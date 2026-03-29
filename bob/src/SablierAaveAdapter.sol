// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Comptrollerable } from "@sablier/evm-utils/src/Comptrollerable.sol";

import { IAavePool } from "./interfaces/external/IAavePool.sol";
import { IAavePoolAddressesProvider } from "./interfaces/external/IAavePoolAddressesProvider.sol";
import { IAavePoolDataProvider } from "./interfaces/external/IAavePoolDataProvider.sol";
import { IAaveAToken } from "./interfaces/external/IAaveToken.sol";
import { ISablierAaveAdapter } from "./interfaces/ISablierAaveAdapter.sol";
import { ISablierBobAdapter } from "./interfaces/ISablierBobAdapter.sol";
import { ISablierBobState } from "./interfaces/ISablierBobState.sol";
import { Errors } from "./libraries/Errors.sol";

/// @title SablierAaveAdapter
/// @notice Aave V3 yield adapter for the SablierBob protocol.
/// @dev This adapter supplies deposited tokens to Aave V3 lending pools to earn interest. Unlike the Lido adapter which
/// only handles WETH, this adapter is token-agnostic: it retrieves the underlying token and aToken per vault at
/// registration time, allowing a single instance to serve all Aave-supported ERC-20 tokens.
///
/// Yield accounting uses Aave's scaled balances. When tokens are supplied, the adapter snapshots the scaled balance
/// delta (before/after) to attribute a precise scaled amount to each user. The scaled balance is immutable — it does
/// not grow. Yield is realized by multiplying the scaled balance by the growing liquidity index at withdrawal time:
///
///     currentValue = scaledBalance * liquidityIndex / 1e27
///
/// This avoids the monolith problem where `aToken.balanceOf(address(this))` conflates all vaults' positions.
contract SablierAaveAdapter is
    Comptrollerable, // 1 inherited component
    ERC165, // 1 inherited component
    ISablierAaveAdapter // 2 inherited components
{
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierAaveAdapter
    IAavePool public immutable override AAVE_POOL;

    /// @inheritdoc ISablierAaveAdapter
    address public immutable override AAVE_POOL_DATA_PROVIDER;

    /// @inheritdoc ISablierBobAdapter
    UD60x18 public constant override MAX_FEE = UD60x18.wrap(0.2e18);

    /// @dev Aave uses RAY (1e27) precision for the liquidity index.
    uint256 private constant RAY = 1e27;

    /// @inheritdoc ISablierBobAdapter
    address public immutable override SABLIER_BOB;

    /// @inheritdoc ISablierBobAdapter
    UD60x18 public override feeOnYield;

    /// @dev Scaled balance held for each user in each vault. The scaled balance encodes both deposit amount AND deposit
    /// time: depositing at a higher liquidity index produces fewer scaled tokens per underlying token. This means
    /// earlier depositors naturally accumulate more yield per token than later depositors, without needing to store
    /// timestamps or index snapshots. See {stake} for how this value is derived.
    mapping(uint256 vaultId => mapping(address user => uint128 scaledBalance)) internal _userScaledBalance;

    /// @dev Total scaled balance held in each vault. This is the sum of all users' scaled balances for the vault.
    /// Used as the denominator in proportional redemption calculations: each user's share of the withdrawn tokens
    /// is `userScaled / totalScaled * totalTokensReceived`.
    mapping(uint256 vaultId => uint128 totalScaledBalance) internal _vaultTotalScaledBalance;

    /// @dev Yield fee snapshotted for each vault at creation time.
    mapping(uint256 vaultId => UD60x18 fee) internal _vaultYieldFee;

    /// @dev Total tokens received after unstaking all positions in a vault.
    mapping(uint256 vaultId => uint128 tokensReceived) internal _tokensReceivedAfterUnstaking;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deploys the Aave V3 adapter.
    /// @param aavePoolAddressesProvider The address of the Aave V3 PoolAddressesProvider (chain-specific).
    /// @param initialComptroller The address of the initial comptroller contract.
    /// @param initialYieldFee The initial yield fee as UD60x18.
    /// @param sablierBob The address of the SablierBob contract.
    constructor(
        address aavePoolAddressesProvider,
        address initialComptroller,
        UD60x18 initialYieldFee,
        address sablierBob
    )
        Comptrollerable(initialComptroller)
    {
        // Check: the yield fee is not too high.
        if (initialYieldFee.gt(MAX_FEE)) {
            revert Errors.SablierAaveAdapter_YieldFeeTooHigh(initialYieldFee, MAX_FEE);
        }

        SABLIER_BOB = sablierBob;

        // Retrieve Aave contracts from the addresses provider.
        IAavePoolAddressesProvider provider = IAavePoolAddressesProvider(aavePoolAddressesProvider);
        AAVE_POOL = IAavePool(provider.getPool());
        AAVE_POOL_DATA_PROVIDER = provider.getPoolDataProvider();

        // Effect: set the initial yield fee.
        feeOnYield = initialYieldFee;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Reverts if the caller is not SablierBob.
    modifier onlySablierBob() {
        if (msg.sender != SABLIER_BOB) {
            revert Errors.SablierAaveAdapter_OnlySablierBob(msg.sender, SABLIER_BOB);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierAaveAdapter
    function getCurrentVaultValue(uint256 vaultId) external view override returns (uint256) {
        uint256 totalScaled = _vaultTotalScaledBalance[vaultId];
        if (totalScaled == 0) {
            return 0;
        }
        IERC20 vaultToken = _getVaultToken(vaultId);
        uint256 currentIndex = AAVE_POOL.getReserveNormalizedIncome(address(vaultToken));
        return totalScaled * currentIndex / RAY;
    }

    /// @inheritdoc ISablierBobAdapter
    function getTotalYieldBearingTokenBalance(uint256 vaultId) external view override returns (uint128) {
        return _vaultTotalScaledBalance[vaultId];
    }

    /// @inheritdoc ISablierAaveAdapter
    function getTokensReceivedAfterUnstaking(uint256 vaultId) external view override returns (uint256) {
        return _tokensReceivedAfterUnstaking[vaultId];
    }

    /// @inheritdoc ISablierBobAdapter
    function getVaultYieldFee(uint256 vaultId) external view override returns (UD60x18) {
        return _vaultYieldFee[vaultId];
    }

    /// @inheritdoc ISablierBobAdapter
    function getYieldBearingTokenBalanceFor(uint256 vaultId, address user) external view override returns (uint128) {
        return _userScaledBalance[vaultId][user];
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ISablierBobAdapter).interfaceId
            || interfaceId == type(ISablierAaveAdapter).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierBobAdapter
    function processRedemption(
        uint256 vaultId,
        address user,
        uint128 shareBalance
    )
        external
        override
        onlySablierBob
        returns (uint128 transferAmount, uint128 feeAmountDeductedFromYield)
    {
        // Get total scaled balance in the vault.
        uint256 totalScaled = _vaultTotalScaledBalance[vaultId];

        // Get total tokens received after unstaking.
        uint256 totalTokens = _tokensReceivedAfterUnstaking[vaultId];

        // If total scaled balance or total tokens received is zero, return zero.
        if (totalScaled == 0 || totalTokens == 0) {
            return (0, 0);
        }

        // Get the user's scaled balance. This encodes both their deposit amount and when they deposited (see {stake}).
        uint256 userScaled = _userScaledBalance[vaultId][user];

        // Calculate the user's proportional share of the withdrawn tokens. Because scaled balances are smaller for
        // later deposits (same amount produces fewer scaled tokens at a higher index), earlier depositors naturally
        // receive a larger share of the total withdrawn tokens per unit deposited.
        uint128 userTokenShare = (userScaled * totalTokens / totalScaled).toUint128();

        // If the user's share is greater than their original deposit (shareBalance), the yield is positive and we
        // need to calculate the fee. The shareBalance is always 1:1 with the deposited amount (minted in SablierBob).
        if (userTokenShare > shareBalance) {
            uint128 yieldAmount = userTokenShare - shareBalance;

            // Calculate the fee.
            feeAmountDeductedFromYield = ud(yieldAmount).mul(_vaultYieldFee[vaultId]).intoUint128();
            transferAmount = userTokenShare - feeAmountDeductedFromYield;
        }
        // Otherwise, the yield is negative or zero, so no fee is applicable.
        else {
            transferAmount = userTokenShare;
        }

        // Effect: clear the user's scaled balance.
        delete _userScaledBalance[vaultId][user];
    }

    /// @inheritdoc ISablierBobAdapter
    function registerVault(uint256 vaultId) external override onlySablierBob {
        // Retrieve the underlying token and validate Aave support.
        IERC20 vaultToken = _getVaultToken(vaultId);
        (address aToken,,) =
            IAavePoolDataProvider(AAVE_POOL_DATA_PROVIDER).getReserveTokensAddresses(address(vaultToken));
        if (aToken == address(0)) {
            revert Errors.SablierAaveAdapter_TokenNotSupportedByAave(address(vaultToken));
        }

        // Effect: snapshot the current global yield fee for this vault.
        _vaultYieldFee[vaultId] = feeOnYield;

        // Interaction: approve the Aave Pool to spend this token.
        vaultToken.forceApprove(address(AAVE_POOL), type(uint128).max);
    }

    /// @inheritdoc ISablierBobAdapter
    function setYieldFee(UD60x18 newFee) external override onlyComptroller {
        // Check: the new fee does not exceed MAX_FEE.
        if (newFee.gt(MAX_FEE)) {
            revert Errors.SablierAaveAdapter_YieldFeeTooHigh(newFee, MAX_FEE);
        }

        UD60x18 previousFee = feeOnYield;

        // Effect: set the new fee.
        feeOnYield = newFee;

        // Log the event.
        emit SetYieldFee(previousFee, newFee);
    }

    /// @inheritdoc ISablierBobAdapter
    function stake(uint256 vaultId, address user, uint256 amount) external override onlySablierBob {
        IERC20 vaultToken = _getVaultToken(vaultId);
        IAaveAToken aToken = _getAToken(vaultToken);

        // Snapshot the contract's total scaled balance before supply. This includes scaled balances from ALL vaults
        // that use this token, but the before/after delta isolates exactly what this single deposit contributed.
        uint256 scaledBefore = aToken.scaledBalanceOf(address(this));

        // Interaction: supply tokens to the Aave Pool. The tokens are already held by this contract (transferred by
        // SablierBob in `_enter`). Approval was set in `registerVault`.
        AAVE_POOL.supply(address(vaultToken), amount, address(this), 0);

        // The scaled balance delta is the exact scaled amount attributable to this deposit. Aave internally computes
        // this as `amount * 1e27 / currentLiquidityIndex`. A deposit made when the index is higher yields fewer
        // scaled tokens per underlying token — this is how deposit timing is encoded without storing timestamps.
        //
        // Example: if index = 1.05e27, depositing 200 tokens produces ~190.48 scaled tokens. A user who deposited
        // 100 tokens when index = 1.0e27 has 100 scaled tokens. At redemption, the first user's 100 scaled tokens
        // represent a larger share of yield than the second user's 190.48 scaled tokens (per underlying token),
        // because the first user's tokens were earning yield for longer.
        uint128 scaledAmount = (aToken.scaledBalanceOf(address(this)) - scaledBefore).toUint128();

        // Effect: track user's scaled balance.
        _userScaledBalance[vaultId][user] += scaledAmount;
        _vaultTotalScaledBalance[vaultId] += scaledAmount;

        // Log the event.
        emit Stake(vaultId, user, amount, scaledAmount);
    }

    /// @inheritdoc ISablierBobAdapter
    function unstakeFullAmount(uint256 vaultId)
        external
        override
        onlySablierBob
        returns (uint128 totalScaledBalance, uint128 amountReceivedFromUnstaking)
    {
        // Get total scaled balance for the vault.
        totalScaledBalance = _vaultTotalScaledBalance[vaultId];
        IERC20 vaultToken = _getVaultToken(vaultId);

        // Convert the vault's total scaled balance back to underlying tokens using the current liquidity index:
        //   currentValue = totalScaledBalance * currentIndex / 1e27
        // This rounds down, so we never ask for more than the contract's aToken balance. The floor division may
        // leave up to 1 wei of aToken dust, which is negligible compared to the yield generated.
        uint256 currentIndex = AAVE_POOL.getReserveNormalizedIncome(address(vaultToken));
        uint256 currentValue = uint256(totalScaledBalance) * currentIndex / RAY;

        // Interaction: withdraw only this vault's portion from Aave. We pass the exact calculated amount (not
        // type(uint256).max) because this contract holds aTokens for multiple vaults of the same token. Using max
        // would drain ALL vaults' positions.
        uint256 actualWithdrawn = AAVE_POOL.withdraw(address(vaultToken), currentValue, address(this));
        amountReceivedFromUnstaking = actualWithdrawn.toUint128();

        // Effect: store the total tokens received. This is the denominator used in {processRedemption} to calculate
        // each user's proportional share: `userScaled / totalScaled * tokensReceived`.
        _tokensReceivedAfterUnstaking[vaultId] = amountReceivedFromUnstaking;

        // Interaction: transfer tokens to SablierBob for distribution.
        vaultToken.safeTransfer(SABLIER_BOB, amountReceivedFromUnstaking);

        // Log the event.
        emit UnstakeFullAmount({
            vaultId: vaultId,
            totalStakedAmount: totalScaledBalance,
            amountReceivedFromUnstaking: amountReceivedFromUnstaking
        });
    }

    /// @inheritdoc ISablierBobAdapter
    function updateStakedTokenBalance(
        uint256 vaultId,
        address from,
        address to,
        uint256 shareAmountTransferred,
        uint256 userShareBalanceBeforeTransfer
    )
        external
        override
        onlySablierBob
    {
        // Check: the user's balance is not zero.
        if (userShareBalanceBeforeTransfer == 0) {
            revert Errors.SablierAaveAdapter_UserBalanceZero(vaultId, from);
        }

        // Calculate proportional scaled balance to transfer.
        uint256 fromScaled = _userScaledBalance[vaultId][from];

        // Calculate the portion of scaled balance to transfer.
        uint128 scaledToTransfer = (fromScaled * shareAmountTransferred / userShareBalanceBeforeTransfer).toUint128();

        // Check: the scaled transfer amount is not zero.
        if (scaledToTransfer == 0) {
            revert Errors.SablierAaveAdapter_ScaledTransferAmountZero(vaultId, from, to);
        }

        // Effect: move scaled balance from sender to recipient.
        _userScaledBalance[vaultId][from] -= scaledToTransfer;
        _userScaledBalance[vaultId][to] += scaledToTransfer;

        // Log the event.
        emit TransferStakedTokens(vaultId, from, to, scaledToTransfer);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Retrieves the aToken for the given underlying token via the Aave PoolDataProvider.
    function _getAToken(IERC20 token) private view returns (IAaveAToken aToken) {
        (address aTokenAddress,,) =
            IAavePoolDataProvider(AAVE_POOL_DATA_PROVIDER).getReserveTokensAddresses(address(token));
        aToken = IAaveAToken(aTokenAddress);
    }

    /// @dev Retrieves the underlying token for the given vault via SablierBob.
    function _getVaultToken(uint256 vaultId) private view returns (IERC20) {
        return ISablierBobState(SABLIER_BOB).getUnderlyingToken(vaultId);
    }
}
