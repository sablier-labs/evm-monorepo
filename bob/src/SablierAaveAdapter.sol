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
import { IAaveToken } from "./interfaces/external/IAaveToken.sol";
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

    /// @dev The Aave token for each supported underlying token.
    mapping(address vaultToken => IAaveToken aaveToken) private _aaveTokens;

    /// @dev The total scaled balance of Aave tokens for each vault.
    mapping(uint256 vaultId => uint256 totalScaledBalance) private _aaveTokenScaledBalances;

    /// @dev Scaled balance of Aave tokens for each user in each vault.
    mapping(uint256 vaultId => mapping(address user => uint256 aaveTokenScaledBalance)) private
        _aaveTokenScaledBalanceFor;

    /// @dev Total tokens received after unstaking all positions in a vault.
    mapping(uint256 vaultId => uint128 tokensReceived) private _tokensReceivedAfterUnstaking;

    /// @dev The underlying token address for each vault.
    mapping(uint256 vaultId => address token) private _vaultTokens;

    /// @dev Yield fee snapshotted for each vault.
    mapping(uint256 vaultId => UD60x18 fee) private _vaultYieldFee;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deploys the Aave V3 adapter.
    /// @param aavePoolAddressesProvider The address of the Aave V3 PoolAddressesProvider.
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
    function getAaveTokenBalanceScaled(uint256 vaultId) external view override returns (uint256) {
        return _aaveTokenScaledBalances[vaultId];
    }

    /// @inheritdoc ISablierAaveAdapter
    function getAaveTokenBalanceScaledFor(uint256 vaultId, address user) external view override returns (uint256) {
        return _aaveTokenScaledBalanceFor[vaultId][user];
    }

    /// @inheritdoc ISablierAaveAdapter
    function getTokensReceivedAfterUnstaking(uint256 vaultId) external view override returns (uint256) {
        return _tokensReceivedAfterUnstaking[vaultId];
    }

    /// @inheritdoc ISablierBobAdapter
    function getTotalYieldBearingTokenBalance(uint256 vaultId) external view override returns (uint128) {
        uint256 aaveTokenScaledBalance = _aaveTokenScaledBalances[vaultId];
        if (aaveTokenScaledBalance == 0) {
            return 0;
        }
        return _calculateUnderlyingAmount(_vaultTokens[vaultId], aaveTokenScaledBalance);
    }

    /// @inheritdoc ISablierBobAdapter
    function getVaultYieldFee(uint256 vaultId) external view override returns (UD60x18) {
        return _vaultYieldFee[vaultId];
    }

    /// @inheritdoc ISablierBobAdapter
    function getYieldBearingTokenBalanceFor(uint256 vaultId, address user) external view override returns (uint128) {
        uint256 userAaveTokenScaledBalance = _aaveTokenScaledBalanceFor[vaultId][user];
        if (userAaveTokenScaledBalance == 0) {
            return 0;
        }
        return _calculateUnderlyingAmount(_vaultTokens[vaultId], userAaveTokenScaledBalance);
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
        uint256 aaveTokenScaledBalance = _aaveTokenScaledBalances[vaultId];

        // Get total tokens received after unstaking.
        uint256 totalTokens = _tokensReceivedAfterUnstaking[vaultId];

        // If total scaled balance or total tokens received is zero, return zero.
        if (aaveTokenScaledBalance == 0 || totalTokens == 0) {
            return (0, 0);
        }

        // Calculate the user's proportional share of the withdrawn tokens.
        uint128 userTokenShare =
            (_aaveTokenScaledBalanceFor[vaultId][user] * totalTokens / aaveTokenScaledBalance).toUint128();

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

        // Effect: clear the user's Aave token scaled balance.
        delete _aaveTokenScaledBalanceFor[vaultId][user];
    }

    /// @inheritdoc ISablierBobAdapter
    function registerVault(uint256 vaultId) external override onlySablierBob {
        // Retrieve the underlying token from SablierBob.
        address vaultToken = address(ISablierBobState(SABLIER_BOB).getUnderlyingToken(vaultId));

        // Retrieve the Aave token address for the underlying token.
        (address aaveTokenAddress,,) =
            IAavePoolDataProvider(AAVE_POOL_DATA_PROVIDER).getReserveTokensAddresses(vaultToken);

        // Check: Aave token address is not the zero address.
        if (aaveTokenAddress == address(0)) {
            revert Errors.SablierAaveAdapter_TokenNotSupportedByAave(address(vaultToken));
        }

        // Effect: store the vault token and Aave token for future lookups.
        _vaultTokens[vaultId] = vaultToken;
        if (_aaveTokens[vaultToken] == IAaveToken(address(0))) {
            _aaveTokens[vaultToken] = IAaveToken(aaveTokenAddress);
        }

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
        // Load the vault token and Aave token into memory.
        address vaultToken = _vaultTokens[vaultId];
        IAaveToken aaveToken = _aaveTokens[vaultToken];

        // Snapshot the contract's total Aave token scaled balance before supply.
        uint256 aaveTokenScaledBalanceBefore = aaveToken.scaledBalanceOf(address(this));

        // Interaction: supply tokens to the Aave Pool.
        AAVE_POOL.supply(vaultToken, amount, address(this), 0);

        // The scaled balance delta is the exact scaled amount attributable to this deposit.
        uint256 aaveTokenAmount = aaveToken.scaledBalanceOf(address(this)) - aaveTokenScaledBalanceBefore;

        // Effect: track user's scaled balance.
        _aaveTokenScaledBalanceFor[vaultId][user] += aaveTokenAmount;
        _aaveTokenScaledBalances[vaultId] += aaveTokenAmount;

        // Log the event.
        emit Stake(vaultId, user, amount, aaveTokenAmount);
    }

    /// @inheritdoc ISablierBobAdapter
    function unstakeFullAmount(uint256 vaultId)
        external
        override
        onlySablierBob
        returns (uint128 vaultTokenBalance, uint128 amountReceivedFromUnstaking)
    {
        // Load the vault token into memory.
        address vaultToken = _vaultTokens[vaultId];

        // Convert the vault's Aave token total scaled balance back to underlying tokens.
        vaultTokenBalance = _calculateUnderlyingAmount(vaultToken, _aaveTokenScaledBalances[vaultId]);

        // Interaction: withdraw only this vault's portion from Aave directly to SablierBob.
        uint256 actualWithdrawn = AAVE_POOL.withdraw(vaultToken, vaultTokenBalance, SABLIER_BOB);
        amountReceivedFromUnstaking = actualWithdrawn.toUint128();

        // Effect: store the total tokens received.
        _tokensReceivedAfterUnstaking[vaultId] = amountReceivedFromUnstaking;

        // Log the event.
        emit UnstakeFullAmount({
            vaultId: vaultId,
            totalStakedAmount: vaultTokenBalance,
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
        uint256 fromScaled = _aaveTokenScaledBalanceFor[vaultId][from];

        // Calculate the portion of scaled balance to transfer.
        uint256 scaledToTransfer = fromScaled * shareAmountTransferred / userShareBalanceBeforeTransfer;

        // Check: the scaled transfer amount is not zero.
        if (scaledToTransfer == 0) {
            revert Errors.SablierAaveAdapter_ScaledTransferAmountZero(vaultId, from, to);
        }

        // Effect: move scaled balance from sender to recipient.
        _aaveTokenScaledBalanceFor[vaultId][from] -= scaledToTransfer;
        _aaveTokenScaledBalanceFor[vaultId][to] += scaledToTransfer;

        // Log the event.
        emit TransferStakedTokens(vaultId, from, to, scaledToTransfer);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Converts a scaled Aave Token amount to the corresponding underlying token amount using the token's current
    /// Aave liquidity index.
    function _calculateUnderlyingAmount(address vaultToken, uint256 scaledAmount) private view returns (uint128) {
        uint256 currentIndex = AAVE_POOL.getReserveNormalizedIncome(vaultToken);
        return (scaledAmount * currentIndex / RAY).toUint128();
    }
}
