// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";

/// @title DataTypes
/// @notice Library with data types used across the core contracts.
library DataTypes {
    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Linear stream struct.
    /// @dev The members are arranged like this to save gas via tight variable packing.
    struct LinearStream {
        uint256 depositAmount;
        uint256 withdrawnAmount;
        address sender; // ───┐
        uint64 startTime; // ─┘
        IERC20 token; // ─────┐
        uint64 cliffTime; // ─┘
        uint64 stopTime; // ─┐
        bool cancelable; // ─┘
    }

    /// @notice Pro stream struct.
    /// @dev Based on the streaming function $f(x) = x^{exponent}$, where x is the elapsed time divided by
    /// the total time.
    /// @member segmentAmounts The amounts of tokens to be streamed in each segment.
    /// @member segmentExponents The exponents in the streaming function.
    /// @member segmentMilestones The unix timestamps in seconds for when each segment ends.
    /// @dev The members are arranged like this to save gas via tight variable packing.
    struct ProStream {
        uint256[] segmentAmounts;
        SD59x18[] segmentExponents;
        uint64[] segmentMilestones;
        uint256 depositAmount;
        uint256 withdrawnAmount;
        address sender; // ───┐
        uint64 startTime; // ─┘
        IERC20 token; // ────┐
        uint64 stopTime; //  │
        bool cancelable; // ─┘
    }
}
