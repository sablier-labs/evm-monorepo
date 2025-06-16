// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Namespace for the structs shared by all Lockup models.
library Lockup {
    /// @notice Struct encapsulating the deposit, withdrawn, and refunded amounts, all denoted in units of the token's
    /// decimals.
    /// @dev The deposited and withdrawn amount are often read together, so declaring them in the same slot saves gas.
    /// @param deposited The amount deposited in the stream.
    /// @param withdrawn The cumulative amount withdrawn from the stream.
    /// @param refunded The amount refunded to the sender. Unless the stream was canceled, this is always zero.
    struct Amounts {
        // slot 0
        uint128 deposited;
        uint128 withdrawn;
        // slot 1
        uint128 refunded;
    }

    /// @notice Struct encapsulating the common parameters emitted in the stream creation events.
    /// @param sender The address distributing the tokens, which is able to cancel the stream.
    /// @param recipient The address receiving the tokens, as well as the NFT owner.
    /// @param depositAmount The deposit amount, denoted in units of the token's decimals.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param cancelable Boolean indicating whether the stream is cancelable or not.
    /// @param transferable Boolean indicating whether the stream NFT is transferable or not.
    /// @param timestamps Struct encapsulating (i) the stream's start time and (ii) end time, all as Unix timestamps.
    /// @param shape An optional parameter to specify the shape of the distribution function. This helps differentiate
    /// streams in the UI.
    struct CreateEventCommon {
        address sender;
        address recipient;
        uint128 depositAmount;
        IERC20 token;
        bool cancelable;
        bool transferable;
        Lockup.Timestamps timestamps;
        string shape;
    }

    /// @notice Struct encapsulating the parameters of the `createWithDurations` functions.
    /// @param sender The address distributing the tokens, with the ability to cancel the stream. It doesn't have to be
    /// the same as `msg.sender`.
    /// @param recipient The address receiving the tokens, as well as the NFT owner.
    /// @param depositAmount The deposit amount, denoted in units of the token's decimals.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param cancelable Indicates if the stream is cancelable.
    /// @param transferable Indicates if the stream NFT is transferable.
    /// @param shape An optional parameter to specify the shape of the distribution function. This helps differentiate
    /// streams in the UI.
    struct CreateWithDurations {
        address sender;
        address recipient;
        uint128 depositAmount;
        IERC20 token;
        bool cancelable;
        bool transferable;
        string shape;
    }

    /// @notice Struct encapsulating the parameters of the `createWithTimestamps` functions.
    /// @param sender The address distributing the tokens, with the ability to cancel the stream. It doesn't have to be
    /// the same as `msg.sender`.
    /// @param recipient The address receiving the tokens, as well as the NFT owner.
    /// @param depositAmount The deposit amount, denoted in units of the token's decimals.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param cancelable Indicates if the stream is cancelable.
    /// @param transferable Indicates if the stream NFT is transferable.
    /// @param timestamps Struct encapsulating (i) the stream's start time and (ii) end time, both as Unix timestamps.
    /// @param shape An optional parameter to specify the shape of the distribution function. This helps differentiate
    /// streams in the UI.
    struct CreateWithTimestamps {
        address sender;
        address recipient;
        uint128 depositAmount;
        IERC20 token;
        bool cancelable;
        bool transferable;
        Timestamps timestamps;
        string shape;
    }

    /// @notice Enum representing the different distribution models used to create Lockup streams.
    /// @dev This determines the streaming function used in the calculations of the unlocked tokens.
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
