// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

/// @notice Simple struct that encapsulates the optional broker parameters that can be passed to the create
/// functions.
/// @param account The address of the broker the fee will be paid to.
/// @param fee The percentage fee that the broker is paid from the total amount, as an UD60x18 number.
struct Broker {
    // slot 0
    address account;
    // slot 1
    UD60x18 fee;
}

/// @notice Quasi-namespace for the structs used in both {SablierV2LockupLinear} and {SablierV2LockupDynamic}.
library Lockup {
    /// @notice Simple struct that encapsulates the deposit and the withdrawn amounts.
    /// @param deposit The amount of assets that have been originally deposited in the stream, net of fees and
    /// in units of the asset's decimals.
    /// @param withdrawn The amount of assets that have been withdrawn from the stream, in units of the asset's
    /// decimals.
    struct Amounts {
        // slot 0
        uint128 deposit;
        uint128 withdrawn;
    }

    /// @notice Simple struct that encapsulates (i) the deposit amount, (ii) the protocol fee amount, and (iii) the
    /// broker fee amount, each in units of the asset's decimals.
    /// @param deposit The amount deposited in the stream, in units of the asset's decimals.
    /// @param protocolFee The protocol fee amount, in units of the asset's decimals.
    /// @param brokerFee The broker fee amount, in units of the asset's decimals.
    struct CreateAmounts {
        uint128 deposit;
        uint128 protocolFee;
        uint128 brokerFee;
    }

    /// @notice Enum with all possible statuses of a lockup stream.
    /// @custom:value NULL The stream has not been created yet. This is the default value.
    /// @custom:value ACTIVE The stream has been created and it is active, indicating that assets are either in
    /// the process of being streamed or are due to be withdrawn.
    /// @custom:value CANCELED The stream has been canceled by either the sender or the recipient.
    /// @custom:value DEPLETED The stream has been depleted, meaning all assets have been withdrawn.
    enum Status {
        NULL,
        ACTIVE,
        CANCELED,
        DEPLETED
    }
}

/// @notice Quasi-namespace for the structs used in {SablierV2LockupDynamic}.
library LockupDynamic {
    /// @notice Struct that encapsulates the parameters of the {SablierV2LockupDynamic-createWithDeltas} function.
    /// @param sender The address from which to stream the assets, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the assets.
    /// @param totalAmount The total amount of ERC-20 assets to be paid, which includes the stream deposit and any
    /// potential fees. This is represented in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset to use for streaming.
    /// @param cancelable Boolean that indicates whether the stream is cancelable or not.
    /// @param segments The segments with deltas the protocol will use to compose the custom streaming curve.
    /// The milestones will be be calculated by adding each delta to `block.timestamp`.
    /// @param broker An optional struct that encapsulates (i) the address of the broker that has helped create the
    /// stream and (ii) the percentage fee that the broker is paid from `totalAmount`, as an UD60x18 number.
    struct CreateWithDeltas {
        LockupDynamic.SegmentWithDelta[] segments;
        address sender;
        bool cancelable;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        Broker broker;
    }

    /// @notice Struct that encapsulates the parameters of the {SablierV2LockupDynamic-createWithMilestones}
    /// function.
    /// @param segments The segments the protocol uses to compose the custom streaming curve.
    /// @param sender The address from which to stream the assets, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param startTime The Unix timestamp for when the stream will start.
    /// @param cancelable Boolean that indicates whether the stream will be cancelable or not.
    /// @param recipient The address toward which to stream the assets.
    /// @param totalAmount The total amount of ERC-20 assets to be paid, which includes the stream deposit and any
    /// potential fees. This is represented in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset to use for streaming.
    /// @param broker An optional struct that encapsulates (i) the address of the broker that has helped create the
    /// stream and (ii) the percentage fee that the broker is paid from `totalAmount`, as an UD60x18 number.
    struct CreateWithMilestones {
        LockupDynamic.Segment[] segments;
        address sender;
        uint40 startTime;
        bool cancelable;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        Broker broker;
    }

    /// @notice Range struct used as a field in the lockup dynamic stream.
    /// @param start The Unix timestamp for when the stream will start.
    /// @param end The Unix timestamp for when the stream will end.
    struct Range {
        uint40 start;
        uint40 end;
    }

    /// @notice Segment struct used in the lockup dynamic stream.
    /// @param amount The amounts of assets to be streamed in this segment, in units of the asset's decimals.
    /// @param exponent The exponent of this segment, as an UD2x18 number.
    /// @param milestone The Unix timestamp for when this segment ends.
    struct Segment {
        // slot 0
        uint128 amount;
        UD2x18 exponent;
        uint40 milestone;
    }

    /// @notice Segment struct used only at runtime in {SablierV2LockupDynamic-createWithDeltas}.
    /// @param amount The amounts of assets to be streamed in this segment, in units of the asset's decimals.
    /// @param exponent The exponent of this segment, as an UD2x18 number.
    /// @param delta The time difference between this segment and the previous one, in seconds.
    struct SegmentWithDelta {
        uint128 amount;
        UD2x18 exponent;
        uint40 delta;
    }

    /// @notice Lockup dynamic stream.
    /// @dev The fields are arranged like this to save gas via tight variable packing.
    /// @param amounts Simple struct with the deposit and the withdrawn amount.
    /// @param segments The segments the protocol uses to compose the custom streaming curve.
    /// @param sender The address of the sender of the stream.
    /// @param startTime The Unix timestamp for when the stream will start.
    /// @param endTime The Unix timestamp for when the stream will end.
    /// @param isCancelable Boolean that indicates whether the stream is cancelable or not.
    /// @param status An enum that indicates the status of the stream.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    struct Stream {
        // slot 0
        Lockup.Amounts amounts;
        // slot 1
        Segment[] segments;
        // slot 2
        address sender;
        uint40 startTime;
        uint40 endTime;
        bool isCancelable;
        Lockup.Status status;
        // slot 3
        IERC20 asset;
    }
}

/// @notice Quasi-namespace for the structs used in {SablierV2LockupLinear}.
library LockupLinear {
    /// @notice Struct that encapsulates the parameters of the {SablierV2LockupLinear-createWithDurations} function.
    /// @param sender The address from which to stream the assets, which will have the ability to
    /// cancel the stream. It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the assets.
    /// @param totalAmount The total amount of ERC-20 assets to be paid, which includes the stream deposit and any
    /// potential fees. This is represented in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset to use for streaming.
    /// @param cancelable Boolean that indicates whether the stream will be cancelable or not.
    /// @param durations Struct that encapsulates (i) the duration of the cliff period and (ii) the total duration of
    /// the stream, both in seconds.
    /// @param broker An optional struct that encapsulates (i) the address of the broker that has helped create the
    /// stream and (ii) the percentage fee that the broker is paid from `totalAmount`, as an UD60x18 number.
    struct CreateWithDurations {
        address sender;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        bool cancelable;
        LockupLinear.Durations durations;
        Broker broker;
    }

    /// @notice Struct that encapsulates the parameters of the {SablierV2LockupLinear-createWithRange} function.
    /// @param sender The address from which to stream the assets, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the assets.
    /// @param totalAmount The total amount of ERC-20 assets to be paid, which includes the stream deposit and any
    /// potential fees. This is represented in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset to use for streaming.
    /// @param cancelable Boolean that indicates whether the stream will be cancelable or not.
    /// @param range Struct that encapsulates (i) the start time of the stream, (ii) the cliff time of the stream,
    /// and (iii) the end time of the stream, all as Unix timestamps.
    /// @param broker An optional struct that encapsulates (i) the address of the broker that has helped create the
    /// stream and (ii) the percentage fee that the broker is paid from `totalAmount`, as an UD60x18 number.
    struct CreateWithRange {
        address sender;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        bool cancelable;
        Range range;
        Broker broker;
    }

    /// @notice Simple struct that encapsulates (i) the cliff duration and (ii) the total duration.
    /// @param cliff The cliff duration in seconds.
    /// @param total The total duration in seconds.
    struct Durations {
        uint40 cliff;
        uint40 total;
    }

    /// @notice Range struct used as a field in the linear lockup linear.
    /// @param start The Unix timestamp for when the stream will start.
    /// @param cliff The Unix timestamp for when the cliff period will end.
    /// @param end The Unix timestamp for when the stream will end.
    struct Range {
        // slot 0
        uint40 start;
        uint40 cliff;
        uint40 end;
    }

    /// @notice linear Lockup linear.
    /// @dev The fields are arranged like this to save gas via tight variable packing.
    /// @param amounts Simple struct with the deposit and the withdrawn amount.
    /// @param sender The address of the sender of the stream.
    /// @param startTime The Unix timestamp for when the stream will start.
    /// @param cliffTime The Unix timestamp for when the cliff period will end.
    /// @param isCancelable Boolean that indicates whether the stream is cancelable or not.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param endTime The Unix timestamp for when the stream will end.
    /// @param status An enum that indicates the status of the stream.
    struct Stream {
        // slot 0
        Lockup.Amounts amounts;
        // slot 1
        address sender;
        uint40 startTime;
        uint40 cliffTime;
        bool isCancelable;
        // slot 2
        IERC20 asset;
        uint40 endTime;
        Lockup.Status status;
    }
}
