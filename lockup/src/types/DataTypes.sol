// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

/// @notice Struct encapsulating the optional broker parameters that can be passed to the create
/// functions.
/// @param account The address of the broker the fee will be paid to.
/// @param fee The percentage fee that the broker is paid from the total amount, as a fixed-point number
/// where 100% = 1e18.
struct Broker {
    address account;
    UD60x18 fee;
}

/// @notice Quasi-namespace for the structs used in both {SablierV2LockupLinear} and {SablierV2LockupDynamic}.
library Lockup {
    /// @notice Struct encapsulating the deposit, withdrawn, and refunded amounts, all denoted in units
    /// of the asset's decimals.
    /// @dev Because the deposited and the withdrawn amount are often read together, declaring them in
    /// the same slot saves gas.
    /// @param deposit The initial amount deposited in the stream, net of fees.
    /// @param withdrawn The cumulative amount withdrawn from the stream.
    /// @param refunded The amount refunded to the sender. Unless the stream is canceled, this is always zero.
    struct Amounts {
        // slot 0
        uint128 deposited;
        uint128 withdrawn;
        // slot 1
        uint128 refunded;
    }

    /// @notice Struct encapsulating the deposit amount, the protocol fee amount, and the broker fee amount,
    /// all denoted in units of the asset's decimals.
    /// @param deposit The amount to deposit in the stream.
    /// @param protocolFee The protocol fee amount.
    /// @param brokerFee The broker fee amount.
    struct CreateAmounts {
        uint128 deposit;
        uint128 protocolFee;
        uint128 brokerFee;
    }

    /// @notice Enum with all possible statuses of a stream.
    /// @custom:value NULL The stream has not been created yet. This is the default value.
    /// @custom:value ACTIVE The stream has been created and it is active, indicating that assets are either in
    /// the process of being streamed or can be withdrawn.
    /// @custom:value CANCELED The stream has been canceled while it was active.
    /// @custom:value DEPLETED The stream has been depleted, meaning all streamed assets have been withdrawn.
    enum Status {
        NULL,
        ACTIVE,
        CANCELED,
        DEPLETED
    }
}

/// @notice Quasi-namespace for the structs used in {SablierV2LockupDynamic}.
library LockupDynamic {
    /// @notice Struct encapsulating the parameters for the {SablierV2LockupDynamic.createWithDeltas} function.
    /// @param sender The address streaming the assets, with the ability to cancel the stream. It doesn't have to be the
    /// same as `msg.sender`.
    /// @param recipient The address receiving the assets.
    /// @param totalAmount The total amount of ERC-20 assets to be paid, including the stream deposit and any potential
    /// fees, all denoted in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param cancelable Indicates if the stream is cancelable.
    /// @param broker Struct containing (i) the address of the broker assisting in stream creation, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, as a fixed-point number. Both can be set to zero.
    /// @param segments Segments with deltas used to compose the custom streaming curve. Milestones are calculated by
    /// starting from `block.timestamp` and adding each delta to the previous milestone.
    struct CreateWithDeltas {
        address sender;
        bool cancelable;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        Broker broker;
        LockupDynamic.SegmentWithDelta[] segments;
    }

    /// @notice Struct encapsulating the parameters for the {SablierV2LockupDynamic.createWithMilestones}
    /// function.
    /// @param sender The address streaming the assets, with the ability to cancel the stream. It doesn't have to be the
    /// same as `msg.sender`.
    /// @param startTime The Unix timestamp indicating the stream's start.
    /// @param cancelable Indicates if the stream is cancelable.
    /// @param recipient The address receiving the assets.
    /// @param totalAmount The total amount of ERC-20 assets to be paid, including the stream deposit and any potential
    /// fees, all denoted in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param broker Struct containing (i) the address of the broker assisting in stream creation, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, as a fixed-point number. Both can be set to zero.
    /// @param segments Segments used to compose the custom streaming curve.
    struct CreateWithMilestones {
        address sender;
        uint40 startTime;
        bool cancelable;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        Broker broker;
        LockupDynamic.Segment[] segments;
    }

    /// @notice Struct encapsulating the time range of a lockup dynamic stream.
    /// @param start The Unix timestamp indicating the stream's start.
    /// @param end The Unix timestamp indicating the stream's end.
    struct Range {
        uint40 start;
        uint40 end;
    }

    /// @notice Segment struct used in the lockup dynamic stream.
    /// @param amount The amount of assets to be streamed in this segment, denoted in units of the asset's decimals.
    /// @param exponent The exponent of this segment, as a fixed-point number.
    /// @param milestone The Unix timestamp indicating this segment's end.
    struct Segment {
        // slot 0
        uint128 amount;
        UD2x18 exponent;
        uint40 milestone;
    }

    /// @notice Segment struct used at runtime in {SablierV2LockupDynamic.createWithDeltas}.
    /// @param amount The amount of assets to be streamed in this segment, denoted in units of the asset's decimals.
    /// @param exponent The exponent of this segment, as a fixed-point number.
    /// @param delta The time difference in seconds between this segment and the previous one.
    struct SegmentWithDelta {
        uint128 amount;
        UD2x18 exponent;
        uint40 delta;
    }

    /// @notice Lockup dynamic stream.
    /// @dev The fields are arranged like this to save gas via tight variable packing.
    /// @param sender The address streaming the assets, with the ability to cancel the stream.
    /// @param startTime The Unix timestamp indicating the stream's start.
    /// @param endTime The Unix timestamp indicating the stream's end.
    /// @param isCancelable Boolean indicating if the stream is cancelable.
    /// @param status An enum representing the stream's status.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param amounts Struct containing the deposit, withdrawn, and refunded amounts, all denoted in units of the
    /// asset's decimals.
    /// @param segments Segments used to compose the custom streaming curve.
    struct Stream {
        // slot 0
        address sender;
        uint40 startTime;
        uint40 endTime;
        bool isCancelable;
        Lockup.Status status;
        // slot 1
        IERC20 asset;
        // slot 2 and 3
        Lockup.Amounts amounts;
        // slots [4..n]
        Segment[] segments;
    }
}

/// @notice Quasi-namespace for the structs used in {SablierV2LockupLinear}.
library LockupLinear {
    /// @notice Struct encapsulating the parameters for the {SablierV2LockupLinear.createWithDurations} function.
    /// @param sender The address streaming the assets, with the ability to cancel the stream. It doesn't have to be the
    /// same as `msg.sender`.
    /// @param recipient The address receiving the assets.
    /// @param totalAmount The total amount of ERC-20 assets to be paid, including the stream deposit and any potential
    /// fees, all denoted in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param cancelable Indicates if the stream is cancelable.
    /// @param durations Struct containing (i) cliff period duration and (ii) total stream duration, both in seconds.
    /// @param broker Struct containing (i) the address of the broker assisting in stream creation, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, as a fixed-point number. Both can be set to zero.
    struct CreateWithDurations {
        address sender;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        bool cancelable;
        LockupLinear.Durations durations;
        Broker broker;
    }

    /// @notice Struct encapsulating the parameters for the {SablierV2LockupLinear.createWithRange} function.
    /// @param sender The address streaming the assets, with the ability to cancel the stream. It doesn't have to be the
    /// same as `msg.sender`.
    /// @param recipient The address receiving the assets.
    /// @param totalAmount The total amount of ERC-20 assets to be paid, including the stream deposit and any potential
    /// fees, all denoted in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param cancelable Indicates if the stream is cancelable.
    /// @param range Struct containing (i) the stream's start time, (ii) cliff time, and (iii) end time, all as Unix
    /// timestamps.
    /// @param broker Struct containing (i) the address of the broker assisting in stream creation, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, as a fixed-point number. Both can be set to zero.
    struct CreateWithRange {
        address sender;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        bool cancelable;
        Range range;
        Broker broker;
    }

    /// @notice Struct encapsulating the cliff duration and the total duration.
    /// @param cliff The cliff duration in seconds.
    /// @param total The total duration in seconds.
    struct Durations {
        uint40 cliff;
        uint40 total;
    }

    /// @notice Struct encapsulating the time range of a lockup linear stream.
    /// @param start The Unix timestamp for the stream's start.
    /// @param cliff The Unix timestamp for the cliff period's end.
    /// @param end The Unix timestamp for the stream's end.
    struct Range {
        uint40 start;
        uint40 cliff;
        uint40 end;
    }

    /// @notice Lockup linear stream.
    /// @dev The fields are arranged like this to save gas via tight variable packing.
    /// @param sender The address streaming the assets, with the ability to cancel the stream.
    /// @param startTime The Unix timestamp indicating the stream's start.
    /// @param cliffTime The Unix timestamp indicating the cliff period's end.
    /// @param isCancelable Boolean indicating if the stream is cancelable.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param startTime The Unix timestamp indicating the stream's end.
    /// @param status An enum representing the stream's status.
    /// @param amounts Struct containing the deposit, withdrawn, and refunded amounts, all denoted in units of the
    /// asset's decimals.
    struct Stream {
        // slot 0
        address sender;
        uint40 startTime;
        uint40 cliffTime;
        bool isCancelable;
        // slot 1
        IERC20 asset;
        uint40 endTime;
        Lockup.Status status;
        // slot 2 and 3
        Lockup.Amounts amounts;
    }
}
