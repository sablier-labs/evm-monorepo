// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

/// @notice Simple struct that encapsulates the deposit and the withdrawn amounts.
/// @custom:field deposit The amount of tokens that have been originally deposited in the stream, net of fees and
/// in units of the token's decimals.
/// @custom:field withdrawn The amount of tokens that have been withdrawn from the stream, in units of the token's
/// decimals.
struct Amounts {
    uint128 deposit; // ───┐
    uint128 withdrawn; // ─┘
}

/// @notice Simple struct that encapsulates the net deposit amount, the protocol fee amount, and the operator fee
/// amount.
/// @custom:field netDeposit The deposit amount net of fees, in units of the token's decimals.
/// @custom:field protocolFee The protocol fee amount, in units of the token's decimals.
/// @custom:field operatorFee The operator fee amount, in units of the token's decimals.
struct CreateAmounts {
    uint128 netDeposit; // ──┐
    uint128 protocolFee; // ─┘
    uint128 operatorFee;
}

/// @notice Simple struct that encapsulates the cliff duration and the total duration.
/// @custom:field cliff The cliff duration in seconds.
/// @custom:field cliff The total duration in seconds.
struct Durations {
    uint40 cliff;
    uint40 total;
}

/// @notice Linear stream struct used in the SablierV2Linear contract.
/// @dev The fields are arranged like this to save gas via tight variable packing.
/// @custom:field amounts Simple struct with the deposit and withdrawn amounts.
/// @custom:field segments The arrays of segments used to compose the custom streaming curve.
/// @custom:field sender The address of the sender of the stream.
/// @custom:field isCancelable A boolean that indicates whether the stream is cancelable or not.
/// @custom:field isEntity A boolean that signals the existence of the instance of the struct.
/// @custom:field token The address of the ERC-20 token used for streaming.
struct LinearStream {
    Amounts amounts;
    Range range;
    address sender; // ───┐
    bool isCancelable; // │
    bool isEntity; // ────┘
    IERC20 token;
}

/// @notice Pro stream struct used in the SablierV2Pro contract.
/// @dev The fields are arranged like this to save gas via tight variable packing.
/// @custom:field amounts Simple struct with the deposit and withdrawn amounts.
/// @custom:field segments The arrays of segments used to compose the custom streaming curve.
/// @custom:field sender The address of the sender of the stream.
/// @custom:field isCancelable A boolean that indicates whether the stream is cancelable or not.
/// @custom:field isEntity A boolean that signals the existence of the instance of the struct.
/// @custom:field token The address of the ERC-20 token used for streaming.
struct ProStream {
    Amounts amounts;
    Segment[] segments;
    address sender; // ───┐
    uint40 startTime; //  │
    bool isCancelable; // │
    bool isEntity; // ────┘
    IERC20 token;
}

/// @notice Range struct used as a field in the linear stream.
/// @custom:field cliff The Unix timestamp for when the cliff period will end.
/// @custom:field start The Unix timestamp for when the stream will start.
/// @custom:field stop The Unix timestamp for when the stream will stop.
struct Range {
    uint40 cliff;
    uint40 start;
    uint40 stop;
}

/// @notice Segment struct used in the SablierV2Pro contract.
/// @custom:field amount The amounts of tokens to be streamed in this segment, in units of the token's decimals.
/// @custom:field exponent The exponent in this segment, whose base is the elapsed time as a percentage.
/// @custom:field milestone The Unix timestamp for when this segment ends.
struct Segment {
    uint128 amount;
    SD1x18 exponent;
    uint40 milestone;
}
