// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

/// @title IERC3156FlashBorrower
/// @notice Interface for ERC-3156 flash borrowers.
/// @dev See https://eips.ethereum.org/EIPS/eip-3156.
interface IERC3156FlashBorrower {
    function onFlashLoan(
        address initiator,
        address asset,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    )
        external
        returns (bytes32);
}
