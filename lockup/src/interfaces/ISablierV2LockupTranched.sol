// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Lockup, LockupTranched } from "../types/DataTypes.sol";
import { ISablierV2Lockup } from "./ISablierV2Lockup.sol";

/// @title ISablierV2LockupTranched
/// @notice Creates and manages Lockup streams with tranches.
interface ISablierV2LockupTranched is ISablierV2Lockup {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a stream is created.
    /// @param streamId The id of the newly created stream.
    /// @param funder The address which has funded the stream.
    /// @param sender The address from which to stream the assets, who will have the ability to cancel the stream.
    /// @param recipient The address toward which to stream the assets.
    /// @param amounts Struct containing (i) the deposit amount, (ii) the protocol fee amount, and (iii) the
    /// broker fee amount, all denoted in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param cancelable Boolean indicating whether the stream will be cancelable or not.
    /// @param transferable Boolean indicating whether the stream NFT is transferable or not.
    /// @param tranches The tranches the protocol uses to compose the custom streaming curve.
    /// @param range Struct containing (i) the stream's start time and (ii) end time, both as Unix timestamps.
    /// @param broker The address of the broker who has helped create the stream, e.g. a front-end website.
    event CreateLockupTranchedStream(
        uint256 streamId,
        address funder,
        address indexed sender,
        address indexed recipient,
        Lockup.CreateAmounts amounts,
        IERC20 indexed asset,
        bool cancelable,
        bool transferable,
        LockupTranched.Tranche[] tranches,
        LockupTranched.Range range,
        address broker
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the stream's range, which is a struct documented in {DataTypes}.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function getRange(uint256 streamId) external view returns (LockupTranched.Range memory range);

    /// @notice Retrieves the stream details, which is a struct documented in {DataTypes}.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function getStream(uint256 streamId) external view returns (LockupTranched.StreamLT memory stream);

    /// @notice Retrieves the tranches the protocol uses to compose the custom distribution curve.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function getTranches(uint256 streamId) external view returns (LockupTranched.Tranche[] memory tranches);

    /// @notice The maximum number of tranches allowed in a stream.
    /// @dev This is initialized at construction time and cannot be changed later.
    function MAX_TRANCHE_COUNT() external view returns (uint256);

    /// @notice Calculates the amount streamed to the recipient, denoted in units of the asset's decimals.
    ///
    /// When the stream is warm, the streaming function is:
    ///
    /// $$
    /// f(x) = \Sigma(esa)
    /// $$
    ///
    /// Where:
    ///
    /// - $\Sigma(esa)$ is the sum of all elapsed tranches' amounts.
    ///
    /// Upon cancellation of the stream, the amount streamed is calculated as the difference between the deposited
    /// amount and the refunded amount. Ultimately, when the stream becomes depleted, the streamed amount is equivalent
    /// to the total amount withdrawn.
    ///
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function streamedAmountOf(uint256 streamId) external view returns (uint128 streamedAmount);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a stream by setting the start time to `block.timestamp`, and the end time to the sum of
    /// `block.timestamp` and all specified time durations. The tranche timestamps are derived from these
    /// durations. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer} and {CreateLockupTrancheStream} event.
    ///
    /// Requirements:
    /// - All requirements in {createWithTimestamps} must be met for the calculated parameters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {DataTypes}.
    /// @return streamId The id of the newly created stream.
    function createWithDurations(LockupTranched.CreateWithDurations calldata params)
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
    /// - If set, `params.broker.fee` must not be greater than `MAX_FEE`.
    /// - `params.tranches` must have at least one tranche, but not more than `MAX_SEGMENT_COUNT`.
    /// - `params.startTime` must be less than the first tranche's timestamp.
    /// - The tranche timestamps must be arranged in ascending order.
    /// - The last tranche timestamp (i.e. the stream's end time) must be in the future.
    /// - The sum of the tranche amounts must equal the deposit amount.
    /// - `params.recipient` must not be the zero address.
    /// - `msg.sender` must have allowed this contract to spend at least `params.totalAmount` assets.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {DataTypes}.
    /// @return streamId The id of the newly created stream.
    function createWithTimestamps(LockupTranched.CreateWithTimestamps calldata params)
        external
        returns (uint256 streamId);
}
