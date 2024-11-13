// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Lockup, LockupDynamic, LockupLinear, LockupTranched } from "../types/DataTypes.sol";
import { ISablierLockupBase } from "./ISablierLockupBase.sol";

/// @title ISablierLockup
/// @notice Creates and manages Lockup streams with various distribution models.
interface ISablierLockup is ISablierLockupBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a stream is created using Lockup dynamic model.
    /// @param streamId The ID of the newly created stream.
    /// @param funder The address which has funded the stream.
    /// @param sender The address distributing the assets, which is able to cancel the stream.
    /// @param recipient The address receiving the assets, as well as the NFT owner.
    /// @param amounts Struct encapsulating (i) the deposit amount, and (ii) the broker fee amount, both denoted
    /// in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param cancelable Boolean indicating whether the stream is cancelable or not.
    /// @param transferable Boolean indicating whether the stream NFT is transferable or not.
    /// @param timestamps Struct encapsulating (i) the stream's start time and (ii) end time, all as Unix timestamps.
    /// @param broker The address of the broker who has helped create the stream, e.g. a front-end website.
    /// @param segments The segments the protocol uses to compose the dynamic distribution function.
    event CreateLockupDynamicStream(
        uint256 streamId,
        address funder,
        address indexed sender,
        address indexed recipient,
        Lockup.CreateAmounts amounts,
        IERC20 indexed asset,
        bool cancelable,
        bool transferable,
        Lockup.Timestamps timestamps,
        LockupDynamic.Segment[] segments,
        address broker
    );

    /// @notice Emitted when a stream is created using Lockup linear model.
    /// @param streamId The ID of the newly created stream.
    /// @param funder The address which funded the stream.
    /// @param sender The address distributing the assets, which is able to to cancel the stream.
    /// @param recipient The address receiving the assets, as well as the NFT owner.
    /// @param amounts Struct encapsulating (i) the deposit amount, and (ii) the broker fee amount, both denoted
    /// in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param cancelable Boolean indicating whether the stream is cancelable or not.
    /// @param transferable Boolean indicating whether the stream NFT is transferable or not.
    /// @param timestamps Struct encapsulating (i) the stream's start time and (ii) end time, all as Unix timestamps.
    /// @param cliffTime The Unix timestamp for the cliff period's end. A value of zero means there is no cliff.
    /// @param broker The address of the broker who has helped create the stream, e.g. a front-end website.
    event CreateLockupLinearStream(
        uint256 streamId,
        address funder,
        address indexed sender,
        address indexed recipient,
        Lockup.CreateAmounts amounts,
        IERC20 indexed asset,
        bool cancelable,
        bool transferable,
        Lockup.Timestamps timestamps,
        uint40 cliffTime,
        address broker
    );

    /// @notice Emitted when a stream is created using Lockup tranched model.
    /// @param streamId The ID of the newly created stream.
    /// @param funder The address which has funded the stream.
    /// @param sender The address distributing the assets, which is able to cancel the stream.
    /// @param recipient The address receiving the assets, as well as the NFT owner.
    /// @param amounts Struct encapsulating (i) the deposit amount, and (ii) the broker fee amount, both denoted
    /// in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param cancelable Boolean indicating whether the stream is cancelable or not.
    /// @param transferable Boolean indicating whether the stream NFT is transferable or not.
    /// @param timestamps Struct encapsulating (i) the stream's start time and (ii) end time, both as Unix timestamps.
    /// @param broker The address of the broker who has helped create the stream, e.g. a front-end website.
    /// @param tranches The tranches the protocol uses to compose the tranched distribution function.
    event CreateLockupTranchedStream(
        uint256 streamId,
        address funder,
        address indexed sender,
        address indexed recipient,
        Lockup.CreateAmounts amounts,
        IERC20 indexed asset,
        bool cancelable,
        bool transferable,
        Lockup.Timestamps timestamps,
        LockupTranched.Tranche[] tranches,
        address broker
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The maximum number of segments and tranches allowed in Dynamic and Tranched streams respectively.
    /// @dev This is initialized at construction time and cannot be changed later.
    function MAX_COUNT() external view returns (uint256);

    /// @notice Retrieves the stream's cliff time, which is a Unix timestamp.  A value of zero means there is no cliff.
    /// @dev Reverts if `streamId` references a null stream or a non Lockup Linear stream.
    /// @param streamId The stream ID for the query.
    function getCliffTime(uint256 streamId) external view returns (uint40 cliffTime);

    /// @notice Retrieves the segments used to compose the dynamic distribution function.
    /// @dev Reverts if `streamId` references a null stream or a non Lockup Dynamic stream.
    /// @param streamId The stream ID for the query.
    function getSegments(uint256 streamId) external view returns (LockupDynamic.Segment[] memory segments);

    /// @notice Retrieves the tranches used to compose the tranched distribution function.
    /// @dev Reverts if `streamId` references a null stream or a non Lockup Tranched stream.
    /// @param streamId The stream ID for the query.
    function getTranches(uint256 streamId) external view returns (LockupTranched.Tranche[] memory tranches);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a stream by setting the start time to `block.timestamp`, and the end time to the sum of
    /// `block.timestamp` and all specified time durations. The segment timestamps are derived from these
    /// durations. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer} and {CreateLockupDynamicStream} event.
    ///
    /// Requirements:
    /// - All requirements in {createWithTimestampsLD} must be met for the calculated parameters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {DataTypes}.
    /// @param segmentsWithDuration Segments with durations used to compose the dynamic distribution function. Timestamps
    /// are calculated by starting from `block.timestamp` and adding each duration to the previous timestamp.
    /// @return streamId The ID of the newly created stream.
    function createWithDurationsLD(
        Lockup.CreateWithDurations calldata params,
        LockupDynamic.SegmentWithDuration[] calldata segmentsWithDuration
    )
        external
        returns (uint256 streamId);

    /// @notice Creates a stream by setting the start time to `block.timestamp`, and the end time to
    /// the sum of `block.timestamp` and `durations.total`. The stream is funded by `msg.sender` and is wrapped in an
    /// ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer} and {CreateLockupLinearStream} event.
    ///
    /// Requirements:
    /// - All requirements in {createWithTimestampsLL} must be met for the calculated parameters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {DataTypes}.
    /// @param durations Struct encapsulating (i) cliff period duration and (ii) total stream duration, both in seconds.
    /// @return streamId The ID of the newly created stream.
    function createWithDurationsLL(
        Lockup.CreateWithDurations calldata params,
        LockupLinear.Durations calldata durations
    )
        external
        returns (uint256 streamId);

    /// @notice Creates a stream by setting the start time to `block.timestamp`, and the end time to the sum of
    /// `block.timestamp` and all specified time durations. The tranche timestamps are derived from these
    /// durations. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer} and {CreateLockupTrancheStream} event.
    ///
    /// Requirements:
    /// - All requirements in {createWithTimestampsLT} must be met for the calculated parameters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {DataTypes}.
    /// @param tranchesWithDuration Tranches with durations used to compose the tranched distribution function.
    /// Timestamps are calculated by starting from `block.timestamp` and adding each duration to the previous timestamp.
    /// @return streamId The ID of the newly created stream.
    function createWithDurationsLT(
        Lockup.CreateWithDurations calldata params,
        LockupTranched.TrancheWithDuration[] calldata tranchesWithDuration
    )
        external
        returns (uint256 streamId);

    /// @notice Creates a stream with the provided segment timestamps, implying the end time from the last timestamp.
    /// The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer} and {CreateLockupDynamicStream} event.
    ///
    /// Notes:
    /// - As long as the segment timestamps are arranged in ascending order, it is not an error for some
    /// of them to be in the past.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `params.totalAmount` must be greater than zero.
    /// - If set, `params.broker.fee` must not be greater than `MAX_BROKER_FEE`.
    /// - `params.timestamps.start` must be greater than zero and less than the first segment's timestamp.
    /// - `segments` must have at least one segment, but not more than `MAX_COUNT`.
    /// - The segment timestamps must be arranged in ascending order.
    /// - `params.timestamps.end` must be equal to the last segment's timestamp.
    /// - The sum of the segment amounts must equal the deposit amount.
    /// - `params.recipient` must not be the zero address.
    /// - `params.sender` must not be the zero address.
    /// - `msg.sender` must have allowed this contract to spend at least `params.totalAmount` assets.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {DataTypes}.
    /// @param segments Segments used to compose the dynamic distribution function.
    /// @return streamId The ID of the newly created stream.
    function createWithTimestampsLD(
        Lockup.CreateWithTimestamps calldata params,
        LockupDynamic.Segment[] calldata segments
    )
        external
        returns (uint256 streamId);

    /// @notice Creates a stream with the provided start time and end time. The stream is funded by `msg.sender` and is
    /// wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer} and {CreateLockupLinearStream} event.
    ///
    /// Notes:
    /// - A cliff time of zero means there is no cliff.
    /// - As long as the times are ordered, it is not an error for the start or the cliff time to be in the past.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `params.totalAmount` must be greater than zero.
    /// - If set, `params.broker.fee` must not be greater than `MAX_BROKER_FEE`.
    /// - `params.timestamps.start` must be greater than zero and less than `params.timestamps.end`.
    /// - If set, `cliffTime` must be greater than `params.timestamps.start` and less than
    /// `params.timestamps.end`.
    /// - `params.recipient` must not be the zero address.
    /// - `params.sender` must not be the zero address.
    /// - `msg.sender` must have allowed this contract to spend at least `params.totalAmount` assets.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {DataTypes}.
    /// @param cliffTime The Unix timestamp for the cliff period's end. A value of zero means there is no cliff.
    /// @return streamId The ID of the newly created stream.
    function createWithTimestampsLL(
        Lockup.CreateWithTimestamps calldata params,
        uint40 cliffTime
    )
        external
        returns (uint256 streamId);

    /// @notice Creates a stream with the provided tranche timestamps, implying the end time from the last timestamp.
    /// The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer} and {CreateLockupTrancheStream} event.
    ///
    /// Notes:
    /// - As long as the tranche timestamps are arranged in ascending order, it is not an error for some
    /// of them to be in the past.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `params.totalAmount` must be greater than zero.
    /// - If set, `params.broker.fee` must not be greater than `MAX_BROKER_FEE`.
    /// - `params.timestamps.start` must be greater than zero and less than the first tranche's timestamp.
    /// - `tranches` must have at least one tranche, but not more than `MAX_COUNT`.
    /// - The tranche timestamps must be arranged in ascending order.
    /// - `params.timestamps.end` must be equal to the last tranche's timestamp.
    /// - The sum of the tranche amounts must equal the deposit amount.
    /// - `params.recipient` must not be the zero address.
    /// - `params.sender` must not be the zero address.
    /// - `msg.sender` must have allowed this contract to spend at least `params.totalAmount` assets.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {DataTypes}.
    /// @param tranches Tranches used to compose the tranched distribution function.
    /// @return streamId The ID of the newly created stream.
    function createWithTimestampsLT(
        Lockup.CreateWithTimestamps calldata params,
        LockupTranched.Tranche[] calldata tranches
    )
        external
        returns (uint256 streamId);
}
