// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { SD1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

/// TODO: document all structs

struct Amounts {
    uint128 deposit; // ───┐
    uint128 withdrawn; // ─┘
}

struct CreateAmounts {
    uint128 netDeposit; // ──┐
    uint128 protocolFee; // ─┘
    uint128 operatorFee;
}

struct CreateWithMilestonesArgs {
    CreateAmounts amounts;
    Segment[] segments;
    address sender; // ──┐
    uint40 startTime; // │
    bool cancelable; // ─┘
    address recipient;
    address operator;
    address token;
}

struct CreateWithRangeArgs {
    CreateAmounts amounts;
    Range range;
    address sender; // ──┐
    bool cancelable; // ─┘
    address recipient;
    address operator;
    address token;
}

/// @notice Linear stream struct.
/// @dev The members are arranged like this to save gas via tight variable packing.
struct LinearStream {
    Amounts amounts;
    Range range;
    address sender; // ───┐
    bool isCancelable; // │
    bool isEntity; // ────┘
    address token;
}

/// @notice Pro stream struct.
/// The members are arranged like this to save gas via tight variable packing.
/// @custom:member segments The segment array used to compose the custom streaming curve.
struct ProStream {
    Amounts amounts;
    Segment[] segments;
    address sender; // ───┐
    uint40 startTime; //  │
    bool isCancelable; // │
    bool isEntity; // ────┘
    address token;
}

struct Range {
    uint40 cliff;
    uint40 start;
    uint40 stop;
}

/// @notice Segment struct.
/// @custom:member amount The amounts of tokens to be streamed in this segment, in units of the token's decimal.
/// @custom:member exponent The exponent in this segment, whose base is the elapsed time as a percentage.
/// @custom:member milestone The unix timestamp in seconds for when this segment ends.
struct Segment {
    uint128 amount;
    SD1x18 exponent;
    uint40 milestone;
}
