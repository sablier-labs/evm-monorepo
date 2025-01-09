// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @notice This contract handles the logic for managing Sablier fees.
interface ISablierFees {
    /// @notice Emitted when the accrued fees are collected.
    /// @param admin The address of the current contract admin, which has received the fees.
    /// @param feeAmount The amount of collected fees.
    event CollectFees(address indexed admin, uint256 indexed feeAmount);

    /// @notice Collects the accrued fees by transferring them to the contract admin.
    ///
    /// @dev Emits a {CollectFees} event.
    ///
    /// Notes:
    /// - If the admin is a contract, it must be able to receive ETH.
    function collectFees() external;
}
