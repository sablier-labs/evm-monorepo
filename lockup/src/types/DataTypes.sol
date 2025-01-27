// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/src/UD2x18.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

// This file defines all structs used in Lockup, most of which are organized under three namespaces:
//
// - BatchLockup
// - Lockup
// - LockupDynamic
// - LockupLinear
// - LockupTranched
//
// You will notice that some structs contain "slot" annotations - they are used to indicate the
// storage layout of the struct. It is more gas efficient to group small data types together so
// that they fit in a single 32-byte slot.

/// @dev Namespace for the structs used in `BatchLockup` contract.
library BatchLockup {
    /// @notice A struct encapsulating all parameters of {SablierLockup.createWithDurationsLD} except for the token.
    struct CreateWithDurationsLD {
        address sender;
        address recipient;
        uint128 totalAmount;
        bool cancelable;
        bool transferable;
        LockupDynamic.SegmentWithDuration[] segmentsWithDuration;
        string shape;
        Broker broker;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockup.createWithDurationsLL} except for the token.
    struct CreateWithDurationsLL {
        address sender;
        address recipient;
        uint128 totalAmount;
        bool cancelable;
        bool transferable;
        LockupLinear.Durations durations;
        LockupLinear.UnlockAmounts unlockAmounts;
        string shape;
        Broker broker;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockup.createWithDurationsLT} except for the token.
    struct CreateWithDurationsLT {
        address sender;
        address recipient;
        uint128 totalAmount;
        bool cancelable;
        bool transferable;
        LockupTranched.TrancheWithDuration[] tranchesWithDuration;
        string shape;
        Broker broker;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockup.createWithTimestampsLD} except for the token.
    struct CreateWithTimestampsLD {
        address sender;
        address recipient;
        uint128 totalAmount;
        bool cancelable;
        bool transferable;
        uint40 startTime;
        LockupDynamic.Segment[] segments;
        string shape;
        Broker broker;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockup.createWithTimestampsLL} except for the token.
    struct CreateWithTimestampsLL {
        address sender;
        address recipient;
        uint128 totalAmount;
        bool cancelable;
        bool transferable;
        Lockup.Timestamps timestamps;
        uint40 cliffTime;
        LockupLinear.UnlockAmounts unlockAmounts;
        string shape;
        Broker broker;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockup.createWithTimestampsLT} except for the token.
    struct CreateWithTimestampsLT {
        address sender;
        address recipient;
        uint128 totalAmount;
        bool cancelable;
        bool transferable;
        uint40 startTime;
        LockupTranched.Tranche[] tranches;
        string shape;
        Broker broker;
    }
}

/// @notice Struct encapsulating the broker parameters passed to the create functions. Both can be set to zero.
/// @param account The address receiving the broker's fee.
/// @param fee The broker's percentage fee from the total amount, denoted as a fixed-point number where 1e18 is 100%.
struct Broker {
    address account;
    UD60x18 fee;
}

/// @notice Namespace for the structs used in all Lockup models.
library Lockup {
    /// @notice Struct encapsulating the deposit, withdrawn, and refunded amounts, all denoted in units of the token's
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
    /// token's decimals.
    /// @param deposit The amount to deposit in the stream.
    /// @param brokerFee The broker fee amount.
    struct CreateAmounts {
        uint128 deposit;
        uint128 brokerFee;
    }

    /// @notice Struct encapsulating the common parameters emitted in the `Create` event.
    /// @param funder The address which has funded the stream.
    /// @param sender The address distributing the tokens, which is able to cancel the stream.
    /// @param recipient The address receiving the tokens, as well as the NFT owner.
    /// @param amounts Struct encapsulating (i) the deposit amount, and (ii) the broker fee amount, both denoted
    /// in units of the token's decimals.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param cancelable Boolean indicating whether the stream is cancelable or not.
    /// @param transferable Boolean indicating whether the stream NFT is transferable or not.
    /// @param timestamps Struct encapsulating (i) the stream's start time and (ii) end time, all as Unix timestamps.
    /// @param shape An optional parameter to specify the shape of the distribution function. This helps differentiate
    /// streams in the UI.
    /// @param broker The address of the broker who has helped create the stream, e.g. a front-end website.
    struct CreateEventCommon {
        address funder;
        address sender;
        address recipient;
        Lockup.CreateAmounts amounts;
        IERC20 token;
        bool cancelable;
        bool transferable;
        Lockup.Timestamps timestamps;
        string shape;
        address broker;
    }

    /// @notice Struct encapsulating the parameters of the `createWithDurations` functions.
    /// @param sender The address distributing the tokens, with the ability to cancel the stream. It doesn't have to be
    /// the same as `msg.sender`.
    /// @param recipient The address receiving the tokens, as well as the NFT owner.
    /// @param totalAmount The total amount, including the deposit and any broker fee, denoted in units of the token's
    /// decimals.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param cancelable Indicates if the stream is cancelable.
    /// @param transferable Indicates if the stream NFT is transferable.
    /// @param shape An optional parameter to specify the shape of the distribution function. This helps differentiate
    /// streams in the UI.
    /// @param broker Struct encapsulating (i) the address of the broker assisting in creating the stream, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, denoted as a fixed-point number. Both can be set to zero.
    struct CreateWithDurations {
        address sender;
        address recipient;
        uint128 totalAmount;
        IERC20 token;
        bool cancelable;
        bool transferable;
        string shape;
        Broker broker;
    }

    /// @notice Struct encapsulating the parameters of the `createWithTimestamps` functions.
    /// @param sender The address distributing the tokens, with the ability to cancel the stream. It doesn't have to be
    /// the same as `msg.sender`.
    /// @param recipient The address receiving the tokens, as well as the NFT owner.
    /// @param totalAmount The total amount, including the deposit and any broker fee, denoted in units of the token's
    /// decimals.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param cancelable Indicates if the stream is cancelable.
    /// @param transferable Indicates if the stream NFT is transferable.
    /// @param timestamps Struct encapsulating (i) the stream's start time and (ii) end time, both as Unix timestamps.
    /// @param shape An optional parameter to specify the shape of the distribution function. This helps differentiate
    /// streams in the UI.
    /// @param broker Struct encapsulating (i) the address of the broker assisting in creating the stream, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, denoted as a fixed-point number. Both can be set to zero.
    struct CreateWithTimestamps {
        address sender;
        address recipient;
        uint128 totalAmount;
        IERC20 token;
        bool cancelable;
        bool transferable;
        Timestamps timestamps;
        string shape;
        Broker broker;
    }

    /// @notice Enum representing the different distribution models used to create lockup streams.
    /// @dev These distribution models determine the vesting function used in the calculations of the unlocked tokens.
    enum Model {
        LOCKUP_LINEAR,
        LOCKUP_DYNAMIC,
        LOCKUP_TRANCHED
    }

    /// @notice Enum representing the different statuses of a stream.
    /// @dev The status can have a "temperature":
    /// 1. Warm: Pending, Streaming. The passage of time alone can change the status.
    /// 2. Cold: Settled, Canceled, Depleted. The passage of time alone cannot change the status.
    /// @custom:value0 PENDING Stream created but not started; tokens are in a pending state.
    /// @custom:value1 STREAMING Active stream where tokens are currently being streamed.
    /// @custom:value2 SETTLED All tokens have been streamed; recipient is due to withdraw them.
    /// @custom:value3 CANCELED Canceled stream; remaining tokens await recipient's withdrawal.
    /// @custom:value4 DEPLETED Depleted stream; all tokens have been withdrawn and/or refunded.
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
    /// @param sender The address distributing the tokens, with the ability to cancel the stream.
    /// @param startTime The Unix timestamp indicating the stream's start.
    /// @param endTime The Unix timestamp indicating the stream's end.
    /// @param isCancelable Boolean indicating if the stream is cancelable.
    /// @param wasCanceled Boolean indicating if the stream was canceled.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param isDepleted Boolean indicating if the stream is depleted.
    /// @param isStream Boolean indicating if the struct entity exists.
    /// @param isTransferable Boolean indicating if the stream NFT is transferable.
    /// @param lockupModel The distribution model of the stream.
    /// @param amounts Struct encapsulating the deposit, withdrawn, and refunded amounts, both denoted in units of the
    /// token's decimals.
    struct Stream {
        // slot 0
        address sender;
        uint40 startTime;
        uint40 endTime;
        bool isCancelable;
        bool wasCanceled;
        // slot 1
        IERC20 token;
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
    /// @param amount The amount of tokens streamed in the segment, denoted in units of the token's decimals.
    /// @param exponent The exponent of the segment, denoted as a fixed-point number.
    /// @param timestamp The Unix timestamp indicating the segment's end.
    struct Segment {
        // slot 0
        uint128 amount;
        UD2x18 exponent;
        uint40 timestamp;
    }

    /// @notice Segment struct used at runtime in {SablierLockup.createWithDurationsLD} function.
    /// @param amount The amount of tokens streamed in the segment, denoted in units of the token's decimals.
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

    /// @notice Struct encapsulating the unlock amounts for the stream.
    /// @dev The sum of `start` and `cliff` must be less than or equal to deposit amount. Both amounts can be zero.
    /// @param start The amount to be unlocked at the start time.
    /// @param cliff The amount to be unlocked at the cliff time.
    struct UnlockAmounts {
        // slot 0
        uint128 start;
        uint128 cliff;
    }
}

/// @notice Namespace for the structs used only in Lockup Tranched model.
library LockupTranched {
    /// @notice Tranche struct to be stored in the Lockup Tranched model.
    /// @param amount The amount of tokens to be unlocked in the tranche, denoted in units of the token's decimals.
    /// @param timestamp The Unix timestamp indicating the tranche's end.
    struct Tranche {
        // slot 0
        uint128 amount;
        uint40 timestamp;
    }

    /// @notice Tranche struct used at runtime in {SablierLockup.createWithDurationsLT} function.
    /// @param amount The amount of tokens to be unlocked in the tranche, denoted in units of the token's decimals.
    /// @param duration The time difference in seconds between the tranche and the previous one.
    struct TrancheWithDuration {
        uint128 amount;
        uint40 duration;
    }
}
