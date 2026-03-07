// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IWETH9
/// @notice Minimal interface for Wrapped Ether.
interface IWETH9 is IERC20 {
    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deposits ETH and mints WETH.
    function deposit() external payable;

    /// @notice Burns WETH and withdraws ETH.
    /// @param amount The amount of WETH to burn.
    function withdraw(uint256 amount) external;
}
