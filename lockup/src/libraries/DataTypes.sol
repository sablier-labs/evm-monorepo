// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

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
        uint128 depositAmount; // ───┐
        uint128 withdrawnAmount; // ─┘
        address sender; // ──┐
        uint40 startTime; // │
        uint40 cliffTime; // │
        bool cancelable; // ─┘
        address token; // ────┐
        uint40 stopTime; // ──┘
    }

    /// @notice Pro stream struct.
    /// @dev Based on the streaming function $f(x) = x^{exponent}$, where x is the elapsed time divided by
    /// the total time.
    /// @member segmentAmounts The amounts of tokens to be streamed in each segment.
    /// @member segmentExponents The exponents in the streaming function.
    /// @member segmentMilestones The unix timestamps in seconds for when each segment ends.
    /// @dev The members are arranged like this to save gas via tight variable packing.
    struct ProStream {
        uint128[] segmentAmounts;
        SD59x18[] segmentExponents;
        uint40[] segmentMilestones;
        uint128 depositAmount; // ───┐
        uint128 withdrawnAmount; // ─┘
        address sender; // ───┐
        uint40 startTime; //  │
        uint40 stopTime; //   │
        bool cancelable; // ──┘
        address token;
    }
}
