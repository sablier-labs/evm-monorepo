// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable func-name-mixedcase
pragma solidity >=0.8.22;

/// @title ICurveStETHPool
/// @notice Minimal interface for the Curve stETH/ETH pool.
/// @dev The pool has two tokens: ETH (index 0) and stETH (index 1).
interface ICurveStETHPool {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Get the amount of output coin for a given input.
    /// @param i The index of the input coin.
    /// @param j The index of the output coin.
    /// @param dx The amount of input coin.
    /// @return dy The expected amount of output coin.
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256 dy);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Exchange between two tokens in the pool.
    /// @param i The index of the input coin (0 = ETH, 1 = stETH).
    /// @param j The index of the output coin (0 = ETH, 1 = stETH).
    /// @param dx The amount of input coin to exchange.
    /// @param minDy The minimum amount of output coin to receive.
    /// @return dy The actual amount of output coin received.
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external payable returns (uint256 dy);
}
