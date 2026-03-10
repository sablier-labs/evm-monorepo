// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IWstETH
/// @notice Minimal interface for Lido's wstETH.
interface IWstETH is IERC20 {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the amount of stETH for a given amount of wstETH.
    /// @param wstETHAmount The amount of wstETH.
    /// @return The equivalent amount of stETH.
    function getStETHByWstETH(uint256 wstETHAmount) external view returns (uint256);

    /// @notice Returns the amount of wstETH for a given amount of stETH.
    /// @param stETHAmount The amount of stETH.
    /// @return The equivalent amount of wstETH.
    function getWstETHByStETH(uint256 stETHAmount) external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Wraps stETH to wstETH.
    function wrap(uint256 stETHAmount) external returns (uint256 wstETHAmount);

    /// @notice Unwraps wstETH to stETH.
    function unwrap(uint256 wstETHAmount) external returns (uint256 stETHAmount);
}
