// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

/// @notice Simple struct that encapsulates the optional broker parameters that can be passed to the create functions.
/// @custom:field account The address of the broker the fee will be paid to.
/// @custom:field fee The percentage fee that the broker is paid from the total amount, as an UD60x18 number.
struct Broker {
    address account;
    UD60x18 fee;
}

/// @notice Quasi-namespace for the structs used in the {SablierV2Lockup} contract.
library Lockup {
    /// @notice Simple struct that encapsulates the deposit and the withdrawn amounts.
    /// @custom:field deposit The amount of assets that have been originally deposited in the stream, net of fees and
    /// in units of the asset's decimals.
    /// @custom:field withdrawn The amount of assets that have been withdrawn from the stream, in units of the asset's
    /// decimals.
    struct Amounts {
        uint128 deposit; // ───┐
        uint128 withdrawn; // ─┘
    }

    /// @notice Simple struct that encapsulates (i) the deposit amount, (ii) the protocol fee amount, and (iii) the
    /// broker fee amount, each in units of the asset's decimals.
    /// @custom:field deposit The amount deposited in the stream, in units of the asset's decimals.
    /// @custom:field protocolFee The protocol fee amount, in units of the asset's decimals.
    /// @custom:field brokerFee The broker fee amount, in units of the asset's decimals.
    struct CreateAmounts {
        uint128 deposit; // ─────┐
        uint128 protocolFee; // ─┘
        uint128 brokerFee;
    }

    /// @notice Enum with all possible statuses of a lockup stream.
    /// @custom:value NULL The stream has not been created yet. This is the default value.
    /// @custom:value ACTIVE The stream has been created and it is active, meaning assets are being streamed.
    /// @custom:value CANCELED The stream has been canceled by either the sender or the recipient.
    /// @custom:value DEPLETED The stream has been depleted, meaning all assets have been withdrawn.
    enum Status {
        NULL,
        ACTIVE,
        CANCELED,
        DEPLETED
    }
}

/// @notice Quasi-namespace for the structs used in the {SablierV2LockupLinear} contract.
library LockupLinear {
    /// @notice Simple struct that encapsulates (i) the cliff duration and (ii) the total duration.
    /// @custom:field cliff The cliff duration in seconds.
    /// @custom:field cliff The total duration in seconds.
    struct Durations {
        uint40 cliff; // ─┐
        uint40 total; // ─┘
    }

    /// @notice Range struct used as a field in the lockup linear stream.
    /// @custom:field start The Unix timestamp for when the stream will start.
    /// @custom:field cliff The Unix timestamp for when the cliff period will end.
    /// @custom:field end The Unix timestamp for when the stream will end.
    struct Range {
        uint40 start; // ─┐
        uint40 cliff; //  │
        uint40 end; // ───┘
    }

    /// @notice Lockup linear stream struct used in the {SablierV2LockupLinear} contract.
    /// @dev The fields are arranged like this to save gas via tight variable packing.
    /// @custom:field amounts Simple struct with the deposit and withdrawn amounts.
    /// @custom:field range Struct that encapsulates (i) the start time of the stream, (ii) the cliff time of the
    /// stream, and (iii) the end time of the stream, all as Unix timestamps.
    /// @custom:field sender The address of the sender of the stream.
    /// @custom:field isCancelable Boolean that indicates whether the stream is cancelable or not.
    /// @custom:field status An enum that indicates the status of the stream.
    /// @custom:field asset The contract address of the ERC-20 asset used for streaming.
    struct Stream {
        Lockup.Amounts amounts;
        Range range;
        address sender; // ───────┐
        bool isCancelable; //     │
        Lockup.Status status; // ─┘
        IERC20 asset;
    }
}

/// @notice Quasi-namespace for the structs used in the {SablierV2LockupPro} contract.
library LockupPro {
    /// @notice Range struct used as a field in the lockup pro stream.
    /// @custom:field start The Unix timestamp for when the stream will start.
    /// @custom:field end The Unix timestamp for when the stream will end.
    struct Range {
        uint40 start; // ─┐
        uint40 end; // ───┘
    }

    /// @notice Segment struct used in the {SablierV2LockupPro} contract.
    /// @custom:field amount The amounts of assets to be streamed in this segment, in units of the asset's decimals.
    /// @custom:field exponent The exponent of this segment, as an UD2x18 number.
    /// @custom:field milestone The Unix timestamp for when this segment ends.
    struct Segment {
        uint128 amount; // ───┐
        UD2x18 exponent; //   │
        uint40 milestone; // ─┘
    }

    /// @notice Segment struct used in the {SablierV2LockupPro-createWithDeltas} function.
    /// @custom:field amount The amounts of assets to be streamed in this segment, in units of the asset's decimals.
    /// @custom:field exponent The exponent of this segment, as an UD2x18 number.
    /// @custom:field delta The time difference between this segment and the previous one, in seconds.
    struct SegmentWithDelta {
        uint128 amount; // ─┐
        UD2x18 exponent; // │
        uint40 delta; // ───┘
    }

    /// @notice Pro stream struct used in the {SablierV2LockupPro} contract.
    /// @dev The fields are arranged like this to save gas via tight variable packing.
    /// @custom:field amounts Simple struct with the deposit and withdrawn amounts.
    /// @custom:field range Simple struct that encapsulates (i) the start time of the stream, and (ii) the end time of
    /// of the stream, both as Unix timestamps.
    /// @custom:field segments The segments the protocol uses to compose the custom streaming curve.
    /// @custom:field sender The address of the sender of the stream.
    /// @custom:field isCancelable Boolean that indicates whether the stream is cancelable or not.
    /// @custom:field status An enum that indicates the status of the stream.
    /// @custom:field asset The contract address of the ERC-20 asset used for streaming.
    struct Stream {
        Lockup.Amounts amounts;
        Range range;
        Segment[] segments;
        address sender; // ───────┐
        bool isCancelable; //     │
        Lockup.Status status; // ─┘
        IERC20 asset;
    }
}
