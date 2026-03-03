// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @title Errors
/// @notice Library with custom errors used across the contracts.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                      ADMINABLE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `msg.sender` is not the admin.
    error CallerNotAdmin(address admin, address caller);

    /*//////////////////////////////////////////////////////////////////////////
                                    COMPTROLLER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the target contract reverts without any return data.
    error SablierComptroller_ExecutionFailedSilently();

    /// @notice Thrown when trying to set fee to a value that exceeds the maximum USD fee.
    error SablierComptroller_MaxFeeUSDExceeded(uint256 newFeeUSD, uint256 maxFeeUSD);

    /// @notice Thrown when an unauthorized address collects fee without setting the fee recipient to admin address.
    error SablierComptroller_FeeRecipientNotAdmin(address feeRecipient, address admin);

    /// @notice Thrown when trying to transfer fees to the zero address.
    error SablierComptroller_FeeRecipientZero();

    /// @notice Thrown if fee transfer fails.
    error SablierComptroller_FeeTransferFailed(address feeRecipient, uint256 feeAmount);

    /// @notice Thrown when trying to withdraw ERC-20 tokens when the balance is zero.
    error SablierComptroller_TokenBalanceZero(address token);

    /// @notice Thrown when trying to withdraw ERC-20 tokens to the zero address.
    error SablierComptroller_ToZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                                  COMPTROLLERABLE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `msg.sender` is not the comptroller.
    error Comptrollerable_CallerNotComptroller(address comptroller, address caller);

    /// @notice Thrown when the new comptroller does not support the minimal interface ID from the previous comptroller.
    error Comptrollerable_UnsupportedInterfaceId(
        address previousComptroller,
        address newComptroller,
        bytes4 minimalInterfaceId
    );

    /*//////////////////////////////////////////////////////////////////////////
                                  NO-DELEGATE-CALL
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to delegate call to a function that disallows delegate calls.
    error DelegateCall();

    /*//////////////////////////////////////////////////////////////////////////
                                    ROLE-ADMINABLE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to grant role to an `account` that already has the `role`.
    error AccountAlreadyHasRole(bytes32 role, address account);

    /// @notice Thrown when trying to revoke role from an `account` that does not have the `role`.
    error AccountDoesNotHaveRole(bytes32 role, address account);

    /// @notice Thrown if `caller` is missing the `neededRole` and is not the admin.
    error UnauthorizedAccess(address caller, bytes32 neededRole);

    /*//////////////////////////////////////////////////////////////////////////
                                   SAFE-ORACLE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when an oracle returns too many decimals (greater than 36).
    error SafeOracle_DecimalsTooHigh(address oracle, uint8 decimals);

    /// @notice Thrown when an oracle returns 0 decimals.
    error SafeOracle_DecimalsZero(address oracle);

    /// @notice Thrown when an oracle does not implement the expected
    /// interface.
    error SafeOracle_MissesInterface(address oracle);

    /// @notice Thrown when the price returned by the oracle is not positive.
    error SafeOracle_NotPositivePrice(address oracle);
}
