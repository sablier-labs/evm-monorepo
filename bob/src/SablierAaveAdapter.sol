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
/// @notice Aave V3 yield adapter for the SablierBob contract.
/// @dev This adapter supplies deposited tokens to Aave V3 lending pools to earn interest. Any ERC20 token supported by
/// Aave V3 can be used as a vault token.
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

    /// @dev Total tokens received after unstaking all positions in a vault.
    mapping(uint256 vaultId => uint128 tokensReceived) private _tokensReceivedAfterUnstaking;

    /// @dev Scaled balance of aTokens for each user in each vault.
    mapping(uint256 vaultId => mapping(address user => uint256 scaledATokenBalance)) private _userATokenScaledBalances;

    /// @dev The aToken address for each vault's underlying token.
    mapping(uint256 vaultId => IAaveAToken aToken) private _vaultATokens;

    /// @dev The underlying token address for each vault.
    mapping(uint256 vaultId => address token) private _vaultTokens;

    /// @dev The total scaled balance of aTokens for each vault.
    mapping(uint256 vaultId => uint256 totalScaledBalance) private _vaultATokenTotalScaledBalance;

    /// @dev Yield fee snapshotted for each vault.
    mapping(uint256 vaultId => UD60x18 fee) private _vaultYieldFee;

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

    /// @inheritdoc ISablierBobAdapter
    function getTotalYieldBearingTokenBalance(uint256 vaultId) external view override returns (uint128) {
        uint256 totalATokenScaled = _vaultATokenTotalScaledBalance[vaultId];
        if (totalATokenScaled == 0) {
            return 0;
        }
        uint256 currentIndex = AAVE_POOL.getReserveNormalizedIncome(_vaultTokens[vaultId]);
        return (totalATokenScaled * currentIndex / RAY).toUint128();
    }

    /// @inheritdoc ISablierAaveAdapter
    function getTokensReceivedAfterUnstaking(uint256 vaultId) external view override returns (uint256) {
        return _tokensReceivedAfterUnstaking[vaultId];
    }

    /// @inheritdoc ISablierAaveAdapter
    function getATokenTotalScaledBalance(uint256 vaultId) external view override returns (uint256) {
        return _vaultATokenTotalScaledBalance[vaultId];
    }

    /// @inheritdoc ISablierAaveAdapter
    function getATokenUserScaledBalance(uint256 vaultId, address user) external view override returns (uint256) {
        return _userATokenScaledBalances[vaultId][user];
    }

    /// @inheritdoc ISablierBobAdapter
    function getVaultYieldFee(uint256 vaultId) external view override returns (UD60x18) {
        return _vaultYieldFee[vaultId];
    }

    /// @inheritdoc ISablierBobAdapter
    function getYieldBearingTokenBalanceFor(uint256 vaultId, address user) external view override returns (uint128) {
        uint256 userATokenScaled = _userATokenScaledBalances[vaultId][user];
        if (userATokenScaled == 0) {
            return 0;
        }
        uint256 currentIndex = AAVE_POOL.getReserveNormalizedIncome(_vaultTokens[vaultId]);
        return (userATokenScaled * currentIndex / RAY).toUint128();
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
        uint256 totalATokenScaled = _vaultATokenTotalScaledBalance[vaultId];

        // Get total tokens received after unstaking.
        uint256 totalTokens = _tokensReceivedAfterUnstaking[vaultId];

        // If total scaled balance or total tokens received is zero, return zero.
        if (totalATokenScaled == 0 || totalTokens == 0) {
            return (0, 0);
        }

        // Calculate the user's proportional share of the withdrawn tokens.
        uint128 userTokenShare =
            (_userATokenScaledBalances[vaultId][user] * totalTokens / totalATokenScaled).toUint128();

        // If the user's share is greater than their original deposit, the yield is positive and we need to calculate
        // the fee.
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

        // Effect: clear the user's aToken scaled balance.
        delete _userATokenScaledBalances[vaultId][user];
    }

    /// @inheritdoc ISablierBobAdapter
    function registerVault(uint256 vaultId) external override onlySablierBob {
        // Retrieve the underlying token from SablierBob.
        address vaultToken = address(ISablierBobState(SABLIER_BOB).getUnderlyingToken(vaultId));

        // Retrieve the aToken address for the underlying token.
        (address aTokenAddress,,) = IAavePoolDataProvider(AAVE_POOL_DATA_PROVIDER).getReserveTokensAddresses(vaultToken);

        // Check: aToken address is not the zero address.
        if (aTokenAddress == address(0)) {
            revert Errors.SablierAaveAdapter_TokenNotSupportedByAave(address(vaultToken));
        }

        // Effect: store the vault token and aToken for future lookups.
        _vaultTokens[vaultId] = vaultToken;
        _vaultATokens[vaultId] = IAaveAToken(aTokenAddress);

        // Effect: snapshot the current global yield fee for this vault.
        _vaultYieldFee[vaultId] = feeOnYield;

        // Interaction: approve the Aave Pool to spend this token.
        IERC20(vaultToken).forceApprove(address(AAVE_POOL), type(uint128).max);
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
        // Load the aToken into memory.
        IAaveAToken aToken = _vaultATokens[vaultId];

        // Snapshot the contract's total aToken scaled balance before supply.
        uint256 scaledATokenBefore = aToken.scaledBalanceOf(address(this));

        // Interaction: supply tokens to the Aave Pool.
        AAVE_POOL.supply(_vaultTokens[vaultId], amount, address(this), 0);

        // The scaled balance delta is the exact scaled amount attributable to this deposit.
        uint256 scaledATokenAmount = aToken.scaledBalanceOf(address(this)) - scaledATokenBefore;

        // Effect: track user's scaled balance.
        _userATokenScaledBalances[vaultId][user] += scaledATokenAmount;
        _vaultATokenTotalScaledBalance[vaultId] += scaledATokenAmount;

        // Log the event.
        emit Stake(vaultId, user, amount, scaledATokenAmount);
    }

    /// @inheritdoc ISablierBobAdapter
    function unstakeFullAmount(uint256 vaultId)
        external
        override
        onlySablierBob
        returns (uint128 totalVaultATokenBalance, uint128 amountReceivedFromUnstaking)
    {
        // Load the vault token into memory.
        address vaultToken = _vaultTokens[vaultId];

        // Convert the vault's aToken total scaled balance back to underlying tokens using the current liquidity index.
        uint256 currentIndex = AAVE_POOL.getReserveNormalizedIncome(vaultToken);
        totalVaultATokenBalance = (_vaultATokenTotalScaledBalance[vaultId] * currentIndex / RAY).toUint128();

        // Interaction: withdraw only this vault's portion from Aave directly to SablierBob.
        uint256 actualWithdrawn = AAVE_POOL.withdraw(vaultToken, totalVaultATokenBalance, SABLIER_BOB);
        amountReceivedFromUnstaking = actualWithdrawn.toUint128();

        // Effect: store the total tokens received.
        _tokensReceivedAfterUnstaking[vaultId] = amountReceivedFromUnstaking;

        // Log the event.
        emit UnstakeFullAmount({
            vaultId: vaultId,
            totalStakedAmount: totalVaultATokenBalance,
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
        uint256 fromScaled = _userATokenScaledBalances[vaultId][from];

        // Calculate the portion of scaled balance to transfer.
        uint256 scaledToTransfer = fromScaled * shareAmountTransferred / userShareBalanceBeforeTransfer;

        // Check: the scaled transfer amount is not zero.
        if (scaledToTransfer == 0) {
            revert Errors.SablierAaveAdapter_ScaledTransferAmountZero(vaultId, from, to);
        }

        // Effect: move scaled balance from sender to recipient.
        _userATokenScaledBalances[vaultId][from] -= scaledToTransfer;
        _userATokenScaledBalances[vaultId][to] += scaledToTransfer;

        // Log the event.
        emit TransferStakedTokens(vaultId, from, to, scaledToTransfer);
    }
}
