// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IStETH
/// @notice Minimal interface for Lido's stETH.
interface IStETH is IERC20 {
    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Send funds to the Lido pool with the optional referral parameter and mints stETH.
    /// @dev The amount of stETH minted equals the amount of ETH sent.
    /// @param referral The referral address can be zero.
    /// @return amount The amount of stETH minted.
    function submit(address referral) external payable returns (uint256 amount);
}
