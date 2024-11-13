// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/src/UD2x18.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

// This file defines all structs used in Lockup, most of which are organized under three namespaces:
//
// - Lockup
// - LockupDynamic
// - LockupLinear
// - LockupTranched
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

/// @notice Namespace for the structs used in all Lockup models.
library Lockup {
    /// @notice Struct encapsulating the deposit, withdrawn, and refunded amounts, all denoted in units of the asset's
    /// decimals.
    /// @dev Because the deposited and the withdrawn amount are often read together, declaring them in the same slot
    /// saves gas.
    /// @param deposited The initial amount deposited in the stream, net of broker fee.
    /// @param withdrawn The cumulative amount withdrawn from the stream.
    /// @param refunded The amount refunded to the sender. Unless the stream was canceled, this is always zero.
    struct Amounts {
        // slot 0
        uint128 deposited;
        uint128 withdrawn;
        // slot 1
        uint128 refunded;
    }

    /// @notice Struct encapsulating (i) the deposit amount and (ii) the broker fee amount, both denoted in units of the
    /// asset's decimals.
    /// @param deposit The amount to deposit in the stream.
    /// @param brokerFee The broker fee amount.
    struct CreateAmounts {
        uint128 deposit;
        uint128 brokerFee;
    }

    /// @notice Struct encapsulating the parameters of the `createWithDurations` functions.
    /// @param sender The address distributing the assets, with the ability to cancel the stream. It doesn't have to be
    /// the same as `msg.sender`.
    /// @param recipient The address receiving the assets, as well as the NFT owner.
    /// @param totalAmount The total amount, including the deposit and any broker fee, denoted in units of the asset's
    /// decimals.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param cancelable Indicates if the stream is cancelable.
    /// @param transferable Indicates if the stream NFT is transferable.
    /// @param broker Struct encapsulating (i) the address of the broker assisting in creating the stream, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, denoted as a fixed-point number. Both can be set to zero.
    struct CreateWithDurations {
        address sender;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        bool cancelable;
        bool transferable;
        Broker broker;
    }

    /// @notice Struct encapsulating the parameters of the `createWithTimestamps` functions.
    /// @param sender The address distributing the assets, with the ability to cancel the stream. It doesn't have to be
    /// the same as `msg.sender`.
    /// @param recipient The address receiving the assets, as well as the NFT owner.
    /// @param totalAmount The total amount, including the deposit and any broker fee, denoted in units of the asset's
    /// decimals.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param cancelable Indicates if the stream is cancelable.
    /// @param transferable Indicates if the stream NFT is transferable.
    /// @param timestamps Struct encapsulating (i) the stream's start time and (ii) end time, both as Unix timestamps.
    /// @param broker Struct encapsulating (i) the address of the broker assisting in creating the stream, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, denoted as a fixed-point number. Both can be set to zero.
    struct CreateWithTimestamps {
        address sender;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        bool cancelable;
        bool transferable;
        Timestamps timestamps;
        Broker broker;
    }

    /// @notice Enum representing the different distribution models used to create lockup streams.
    /// @dev These distribution models determine the vesting function used in the calculations of the unlocked assets.
    enum Model {
        LOCKUP_LINEAR,
        LOCKUP_DYNAMIC,
        LOCKUP_TRANCHED
    }

    /// @notice Enum representing the different statuses of a stream.
    /// @dev The status can have a "temperature":
    /// 1. Warm: Pending, Streaming. The passage of time alone can change the status.
    /// 2. Cold: Settled, Canceled, Depleted. The passage of time alone cannot change the status.
    /// @custom:value0 PENDING Stream created but not started; assets are in a pending state.
    /// @custom:value1 STREAMING Active stream where assets are currently being streamed.
    /// @custom:value2 SETTLED All assets have been streamed; recipient is due to withdraw them.
    /// @custom:value3 CANCELED Canceled stream; remaining assets await recipient's withdrawal.
    /// @custom:value4 DEPLETED Depleted stream; all assets have been withdrawn and/or refunded.
    enum Status {
        // Warm
        PENDING,
        STREAMING,
        // Cold
        SETTLED,
        CANCELED,
        DEPLETED
    }

    /// @notice A common data structure to be stored in all Lockup models.
    /// @dev The fields are arranged like this to save gas via tight variable packing.
    /// @param sender The address distributing the assets, with the ability to cancel the stream.
    /// @param startTime The Unix timestamp indicating the stream's start.
    /// @param endTime The Unix timestamp indicating the stream's end.
    /// @param isCancelable Boolean indicating if the stream is cancelable.
    /// @param wasCanceled Boolean indicating if the stream was canceled.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param isDepleted Boolean indicating if the stream is depleted.
    /// @param isStream Boolean indicating if the struct entity exists.
    /// @param isTransferable Boolean indicating if the stream NFT is transferable.
    /// @param lockupModel The distribution model of the stream.
    /// @param amounts Struct encapsulating the deposit, withdrawn, and refunded amounts, both denoted in units of the
    /// asset's decimals.
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
        bool isTransferable;
        Model lockupModel;
        // slot 2 and 3
        Amounts amounts;
    }

    /// @notice Struct encapsulating the Lockup timestamps.
    /// @param start The Unix timestamp for the stream's start.
    /// @param end The Unix timestamp for the stream's end.
    struct Timestamps {
        uint40 start;
        uint40 end;
    }
}

/// @notice Namespace for the structs used only in Lockup Dynamic model.
library LockupDynamic {
    /// @notice Segment struct to be stored in the Lockup Dynamic model.
    /// @param amount The amount of assets streamed in the segment, denoted in units of the asset's decimals.
    /// @param exponent The exponent of the segment, denoted as a fixed-point number.
    /// @param timestamp The Unix timestamp indicating the segment's end.
    struct Segment {
        // slot 0
        uint128 amount;
        UD2x18 exponent;
        uint40 timestamp;
    }

    /// @notice Segment struct used at runtime in {SablierLockup.createWithDurationsLD} function.
    /// @param amount The amount of assets streamed in the segment, denoted in units of the asset's decimals.
    /// @param exponent The exponent of the segment, denoted as a fixed-point number.
    /// @param duration The time difference in seconds between the segment and the previous one.
    struct SegmentWithDuration {
        uint128 amount;
        UD2x18 exponent;
        uint40 duration;
    }
}

/// @notice Namespace for the structs used only in Lockup Linear model.
library LockupLinear {
    /// @notice Struct encapsulating the cliff duration and the total duration used at runtime in
    /// {SablierLockup.createWithDurationsLL} function.
    /// @param cliff The cliff duration in seconds.
    /// @param total The total duration in seconds.
    struct Durations {
        uint40 cliff;
        uint40 total;
    }
}

/// @notice Namespace for the structs used only in Lockup Tranched model.
library LockupTranched {
    /// @notice Tranche struct to be stored in the Lockup Tranched model.
    /// @param amount The amount of assets to be unlocked in the tranche, denoted in units of the asset's decimals.
    /// @param timestamp The Unix timestamp indicating the tranche's end.
    struct Tranche {
        // slot 0
        uint128 amount;
        uint40 timestamp;
    }

    /// @notice Tranche struct used at runtime in {SablierLockup.createWithDurationsLT} function.
    /// @param amount The amount of assets to be unlocked in the tranche, denoted in units of the asset's decimals.
    /// @param duration The time difference in seconds between the tranche and the previous one.
    struct TrancheWithDuration {
        uint128 amount;
        uint40 duration;
    }
}
