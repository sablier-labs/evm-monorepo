// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Escrow } from "../types/Escrow.sol";

/// @title Errors
/// @notice Library containing all custom errors emitted by the Sablier Bob protocol.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                  BOB VAULT SHARE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when a function is called by an address other than SablierBob.
    error BobVaultShare_OnlySablierBob(address caller, address expectedCaller);

    /// @notice Thrown when the provided vault ID does not match the share token's vault ID.
    error BobVaultShare_VaultIdMismatch(uint256 providedVaultId, uint256 expectedVaultId);

    /*//////////////////////////////////////////////////////////////////////////
                                    SABLIER BOB
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `onShareTransfer` is called by an address other than the share token.
    error SablierBob_CallerNotShareToken(uint256 vaultId, address caller);

    /// @notice Thrown when depositing zero amount in a vault.
    error SablierBob_DepositAmountZero(uint256 vaultId, address user);

    /// @notice Thrown when trying to create a vault with an expiry timestamp not in the future.
    error SablierBob_ExpiryNotInFuture(uint40 expiry, uint40 currentTime);

    /// @notice Thrown when trying to create a vault with the native token.
    error SablierBob_ForbidNativeToken(address nativeToken);

    /// @notice Thrown when trying to redeem with `msg.value` less than the minimum fee required.
    error SablierBob_InsufficientFeePayment(uint256 feePaid, uint256 feeRequired);

    /// @notice Thrown when trying to pay a fee in the native token from a vault that uses the adapter.
    error SablierBob_MsgValueNotZero(uint256 vaultId);

    /// @notice Thrown when the native token fee transfer to the comptroller fails.
    error SablierBob_NativeFeeTransferFailed();

    /// @notice Thrown when trying to set the native token address when it is already set.
    error SablierBob_NativeTokenAlreadySet(address nativeToken);

    /// @notice Thrown when trying to set zero address as native token.
    error SablierBob_NativeTokenZeroAddress();

    /// @notice Thrown when the new adapter does not implement the required interface.
    error SablierBob_NewAdapterMissesInterface(address adapter);

    /// @notice Thrown when trying to exit or redeem with zero share balance.
    error SablierBob_NoSharesToRedeem(uint256 vaultId, address user);

    /// @notice Thrown when trying to create a vault with a zero target price.
    error SablierBob_TargetPriceZero();

    /// @notice Thrown when trying to create a vault with a target price that is not greater than the latest price
    /// returned by the oracle.
    error SablierBob_TargetPriceTooLow(uint128 targetPrice, uint128 currentPrice);

    /// @notice Thrown when trying to create a vault with a zero token address.
    error SablierBob_TokenAddressZero();

    /// @notice Thrown when trying to unstake vault tokens using the adapter but the amount staked is zero.
    error SablierBob_UnstakeAmountZero(uint256 vaultId);

    /// @notice Thrown when trying to unstake vault tokens using the adapter but the vault has already been unstaked.
    error SablierBob_VaultAlreadyUnstaked(uint256 vaultId);

    /// @notice Thrown when trying to unstake from a vault that has no adapter configured.
    error SablierBob_VaultHasNoAdapter(uint256 vaultId);

    /// @notice Thrown when trying to perform an unauthorized action on a non-active vault.
    error SablierBob_VaultNotActive(uint256 vaultId);

    /// @notice Thrown when trying to perform an unauthorized action on an active vault.
    error SablierBob_VaultStillActive(uint256 vaultId);

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER BOB STATE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to interact with a non-existent vault.
    error SablierBobState_Null(uint256 vaultId);

    /*//////////////////////////////////////////////////////////////////////////
                                   SABLIER ESCROW
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create an order with a zero address for the buy token.
    error SablierEscrow_BuyTokenZero();

    /// @notice Thrown when the caller is not authorized to perform an action on an order.
    error SablierEscrow_CallerNotAuthorized(uint256 orderId, address caller, address expectedCaller);

    /// @notice Thrown when trying to create an order with an expiration timestamp in the past.
    error SablierEscrow_ExpiryTimeInPast(uint40 expiryTime, uint40 currentTime);

    /// @notice Thrown when trying to create an order with the native token.
    error SablierEscrow_ForbidNativeToken(address nativeToken);

    /// @notice Thrown when trying to accept an order with a buy amount that is below the minimum amount required.
    error SablierEscrow_InsufficientBuyAmount(uint128 buyAmount, uint128 minBuyAmount);

    /// @notice Thrown when trying to create an order with a zero buy amount.
    error SablierEscrow_MinBuyAmountZero();

    /// @notice Thrown when trying to set the native token address when it is already set.
    error SablierEscrow_NativeTokenAlreadySet(address nativeToken);

    /// @notice Thrown when trying to set zero address as native token.
    error SablierEscrow_NativeTokenZeroAddress();

    /// @notice Thrown when trying to cancel an order that has already been canceled.
    error SablierEscrow_OrderCancelled(uint256 orderId);

    /// @notice Thrown when trying to cancel an order that has already been filled.
    error SablierEscrow_OrderFilled(uint256 orderId);

    /// @notice Thrown when trying to fill an order that has either been completed or canceled.
    error SablierEscrow_OrderNotOpen(uint256 orderId, Escrow.Status status);

    /// @notice Thrown when trying to create an order with the same sell and buy tokens.
    error SablierEscrow_SameToken(IERC20 token);

    /// @notice Thrown when trying to create an order with a zero sell amount.
    error SablierEscrow_SellAmountZero();

    /// @notice Thrown when trying to create an order with a zero address for the sell token.
    error SablierEscrow_SellTokenZero();

    /*//////////////////////////////////////////////////////////////////////////
                                SABLIER ESCROW STATE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to set a trade fee that exceeds the maximum allowed.
    error SablierEscrowState_NewTradeFeeTooHigh(UD60x18 newTradeFee, UD60x18 maxTradeFee);

    /// @notice Thrown when trying to interact with a non-existent order.
    error SablierEscrowState_Null(uint256 orderId);

    /*//////////////////////////////////////////////////////////////////////////
                                SABLIER LIDO ADAPTER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to request a Lido withdrawal for a vault that has already requested one.
    error SablierLidoAdapter_LidoWithdrawalAlreadyRequested(uint256 vaultId);

    /// @notice Thrown when trying to request a Lido withdrawal for a vault with no wstETH.
    error SablierLidoAdapter_NoWstETHToWithdraw(uint256 vaultId);

    /// @notice Thrown when a function is called by an address other than SablierBob.
    error SablierLidoAdapter_OnlySablierBob(address caller, address expectedCaller);

    /// @notice Thrown when the Curve swap output is below the minimum acceptable amount.
    error SablierLidoAdapter_SlippageExceeded(uint256 expected, uint256 actual);

    /// @notice Thrown when trying to set a slippage that exceeds the maximum allowed.
    error SablierLidoAdapter_SlippageToleranceTooHigh(UD60x18 tolerance, UD60x18 maxTolerance);

    /// @notice Thrown when trying to update staked token balance but the user's balance is zero.
    error SablierLidoAdapter_UserBalanceZero(uint256 vaultId, address user);

    /// @notice Thrown when trying to request a Lido withdrawal for a vault that is active.
    error SablierLidoAdapter_VaultActive(uint256 vaultId);

    /// @notice Thrown when trying to request a Lido withdrawal for a vault that has already been unstaked.
    error SablierLidoAdapter_VaultAlreadyUnstaked(uint256 vaultId);

    /// @notice Thrown when the calculated wstETH transfer amount rounds down to zero due to floor division.
    error SablierLidoAdapter_WstETHTransferAmountZero(uint256 vaultId, address from, address to);

    /// @notice Thrown when the total amount to withdraw is below the minimum amount per request.
    error SablierLidoAdapter_WithdrawalAmountBelowMinimum(
        uint256 vaultId,
        uint256 totalAmount,
        uint256 minimumAmountPerRequest
    );

    /// @notice Thrown when trying to set a yield fee that exceeds the maximum allowed.
    error SablierLidoAdapter_YieldFeeTooHigh(UD60x18 fee, UD60x18 maxFee);
}
