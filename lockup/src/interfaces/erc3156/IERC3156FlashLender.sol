// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { IERC3156FlashBorrower } from "./IERC3156FlashBorrower.sol";

/// @title IERC3156FlashLender
/// @notice Interface for ERC-3156 flash lenders.
/// @dev See https://eips.ethereum.org/EIPS/eip-3156.
interface IERC3156FlashLender {
    function maxFlashLoan(address asset) external view returns (uint256);

    function flashFee(address asset, uint256 amount) external view returns (uint256);

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address asset,
        uint256 amount,
        bytes calldata data
    )
        external
        returns (bool);
}
