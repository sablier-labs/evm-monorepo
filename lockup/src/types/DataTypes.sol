// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/src/UD2x18.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

// DataTypes.sol
//
// This file defines all structs used in V2 Core, most of which are organized under three namespaces:
//
// - Lockup
// - LockupDynamic
// - LockupLinear
//
// You will notice that some structs contain "slot" annotations - they are used to indicate the
// storage layout of the struct. It is more gas efficient to group small data types together so
// that they fit in a single 32-byte slot.

/// @notice Struct encapsulating the broker parameters passed to the create functions. Both can be set to zero.
/// @param account The address receiving the broker's fee.
/// @param fee The broker's percentage fee from the total amount, denoted as a fixed-point number where 1e18 is 100%.
struct Broker {
    address account;
    UD60x18 fee;
}

/// @notice Namespace for the structs used in both {SablierV2LockupLinear} and {SablierV2LockupDynamic}.
library Lockup {
    /// @notice Struct encapsulating the deposit, withdrawn, and refunded amounts, all denoted in units
    /// of the asset's decimals.
    /// @dev Because the deposited and the withdrawn amount are often read together, declaring them in
    /// the same slot saves gas.
    /// @param deposited The initial amount deposited in the stream, net of fees.
    /// @param withdrawn The cumulative amount withdrawn from the stream.
    /// @param refunded The amount refunded to the sender. Unless the stream was canceled, this is always zero.
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

    /// @notice Enum representing the different statuses of a stream.
    /// @custom:value PENDING Stream created but not started; assets are in a pending state.
    /// @custom:value STREAMING Active stream where assets are currently being streamed.
    /// @custom:value SETTLED All assets have been streamed; recipient is due to withdraw them.
    /// @custom:value CANCELED Canceled stream; remaining assets await recipient's withdrawal.
    /// @custom:value DEPLETED Depleted stream; all assets have been withdrawn and/or refunded.
    enum Status {
        PENDING, // value 0
        STREAMING, // value 1
        SETTLED, // value 2
        CANCELED, // value 3
        DEPLETED // value 4
    }
}

/// @notice Namespace for the structs used in {SablierV2LockupDynamic}.
library LockupDynamic {
    /// @notice Struct encapsulating the parameters for the {SablierV2LockupDynamic.createWithDeltas} function.
    /// @param sender The address streaming the assets, with the ability to cancel the stream. It doesn't have to be the
    /// same as `msg.sender`.
    /// @param recipient The address receiving the assets.
    /// @param totalAmount The total amount of ERC-20 assets to be paid, including the stream deposit and any potential
    /// fees, all denoted in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param cancelable Indicates if the stream is cancelable.
    /// @param broker Struct containing (i) the address of the broker assisting in creating the stream, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, denoted as a fixed-point number. Both can be set to zero.
    /// @param segments Segments with deltas used to compose the custom streaming curve. Milestones are calculated by
    /// starting from `block.timestamp` and adding each delta to the previous milestone.
    struct CreateWithDeltas {
        address sender;
        bool cancelable;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        Broker broker;
        SegmentWithDelta[] segments;
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
    /// @param broker Struct containing (i) the address of the broker assisting in creating the stream, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, denoted as a fixed-point number. Both can be set to zero.
    /// @param segments Segments used to compose the custom streaming curve.
    struct CreateWithMilestones {
        address sender;
        uint40 startTime;
        bool cancelable;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        Broker broker;
        Segment[] segments;
    }

    /// @notice Struct encapsulating the time range.
    /// @param start The Unix timestamp indicating the stream's start.
    /// @param end The Unix timestamp indicating the stream's end.
    struct Range {
        uint40 start;
        uint40 end;
    }

    /// @notice Segment struct used in the Lockup Dynamic stream.
    /// @param amount The amount of assets to be streamed in this segment, denoted in units of the asset's decimals.
    /// @param exponent The exponent of this segment, denoted as a fixed-point number.
    /// @param milestone The Unix timestamp indicating this segment's end.
    struct Segment {
        // slot 0
        uint128 amount;
        UD2x18 exponent;
        uint40 milestone;
    }

    /// @notice Segment struct used at runtime in {SablierV2LockupDynamic.createWithDeltas}.
    /// @param amount The amount of assets to be streamed in this segment, denoted in units of the asset's decimals.
    /// @param exponent The exponent of this segment, denoted as a fixed-point number.
    /// @param delta The time difference in seconds between this segment and the previous one.
    struct SegmentWithDelta {
        uint128 amount;
        UD2x18 exponent;
        uint40 delta;
    }

    /// @notice Lockup Dynamic stream.
    /// @dev The fields are arranged like this to save gas via tight variable packing.
    /// @param sender The address streaming the assets, with the ability to cancel the stream.
    /// @param startTime The Unix timestamp indicating the stream's start.
    /// @param endTime The Unix timestamp indicating the stream's end.
    /// @param isCancelable Boolean indicating if the stream is cancelable.
    /// @param wasCanceled Boolean indicating if the stream was canceled.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param isDepleted Boolean indicating if the stream is depleted.
    /// @param isStream Boolean indicating if the struct entity exists.
    /// @param amounts Struct containing the deposit, withdrawn, and refunded amounts, all denoted in units of the
    /// asset's decimals.
    /// @param segments Segments used to compose the custom streaming curve.
    struct Stream {
        // slot 0
        address sender;
        uint40 startTime;
        uint40 endTime;
        bool isCancelable;
        bool wasCanceled;
        // slot 1
        IERC20 asset;
        bool isDepleted;
        bool isStream;
        // slot 2 and 3
        Lockup.Amounts amounts;
        // slots [4..n]
        Segment[] segments;
    }
}

/// @notice Namespace for the structs used in {SablierV2LockupLinear}.
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
    /// @param broker Struct containing (i) the address of the broker assisting in creating the stream, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, denoted as a fixed-point number. Both can be set to zero.
    struct CreateWithDurations {
        address sender;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        bool cancelable;
        Durations durations;
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
    /// @param broker Struct containing (i) the address of the broker assisting in creating the stream, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, denoted as a fixed-point number. Both can be set to zero.
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

    /// @notice Struct encapsulating the time range.
    /// @param start The Unix timestamp for the stream's start.
    /// @param cliff The Unix timestamp for the cliff period's end.
    /// @param end The Unix timestamp for the stream's end.
    struct Range {
        uint40 start;
        uint40 cliff;
        uint40 end;
    }

    /// @notice Lockup Linear stream.
    /// @dev The fields are arranged like this to save gas via tight variable packing.
    /// @param sender The address streaming the assets, with the ability to cancel the stream.
    /// @param startTime The Unix timestamp indicating the stream's start.
    /// @param cliffTime The Unix timestamp indicating the cliff period's end.
    /// @param isCancelable Boolean indicating if the stream is cancelable.
    /// @param wasCanceled Boolean indicating if the stream was canceled.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param endTime The Unix timestamp indicating the stream's end.
    /// @param isDepleted Boolean indicating if the stream is depleted.
    /// @param isStream Boolean indicating if the struct entity exists.
    /// @param amounts Struct containing the deposit, withdrawn, and refunded amounts, all denoted in units of the
    /// asset's decimals.
    struct Stream {
        // slot 0
        address sender;
        uint40 startTime;
        uint40 cliffTime;
        bool isCancelable;
        bool wasCanceled;
        // slot 1
        IERC20 asset;
        uint40 endTime;
        bool isDepleted;
        bool isStream;
        // slot 2 and 3
        Lockup.Amounts amounts;
    }
}
