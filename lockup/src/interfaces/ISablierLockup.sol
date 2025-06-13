// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IBatch } from "@sablier/evm-utils/src/interfaces/IBatch.sol";
import { IComptrollerManager } from "@sablier/evm-utils/src/interfaces/IComptrollerManager.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { Lockup, LockupDynamic, LockupLinear, LockupTranched } from "../types/DataTypes.sol";
import { ILockupNFTDescriptor } from "./ILockupNFTDescriptor.sol";
import { ISablierLockupState } from "./ISablierLockupState.sol";

/// @title ISablierLockup
/// @notice Creates and manages Lockup streams with various distribution models.
interface ISablierLockup is
    IBatch, // 0 inherited components
    IComptrollerManager, // 0 inherited components
    IERC4906, // 2 inherited components
    IERC721Metadata, // 1 inherited component
    ISablierLockupState // 0 inherited components
{
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the comptroller allows a new recipient contract to hook to Sablier.
    /// @param comptroller The address of the current comptroller.
    /// @param recipient The address of the recipient contract put on the allowlist.
    event AllowToHook(ISablierComptroller indexed comptroller, address indexed recipient);

    /// @notice Emitted when a stream is canceled.
    /// @param streamId The ID of the stream.
    /// @param sender The address of the stream's sender.
    /// @param recipient The address of the stream's recipient.
    /// @param token The contract address of the ERC-20 token that has been distributed.
    /// @param senderAmount The amount of tokens refunded to the stream's sender, denoted in units of the token's
    /// decimals.
    /// @param recipientAmount The amount of tokens left for the stream's recipient to withdraw, denoted in units of the
    /// token's decimals.
    event CancelLockupStream(
        uint256 streamId,
        address indexed sender,
        address indexed recipient,
        IERC20 indexed token,
        uint128 senderAmount,
        uint128 recipientAmount
    );

    /// @notice Emitted when an LD stream is created.
    /// @param streamId The ID of the newly created stream.
    /// @param commonParams Common parameters emitted in Create events across all Lockup models.
    /// @param segments The segments the protocol uses to compose the dynamic distribution function.
    event CreateLockupDynamicStream(
        uint256 indexed streamId, Lockup.CreateEventCommon commonParams, LockupDynamic.Segment[] segments
    );

    /// @notice Emitted when an LL stream is created.
    /// @param streamId The ID of the newly created stream.
    /// @param commonParams Common parameters emitted in Create events across all Lockup models.
    /// @param cliffTime The Unix timestamp for the cliff period's end. A value of zero means there is no cliff.
    /// @param unlockAmounts Struct encapsulating (i) the amount to unlock at the start time and (ii) the amount to
    /// unlock at the cliff time.
    event CreateLockupLinearStream(
        uint256 indexed streamId,
        Lockup.CreateEventCommon commonParams,
        uint40 cliffTime,
        LockupLinear.UnlockAmounts unlockAmounts
    );

    /// @notice Emitted when an LT stream is created.
    /// @param streamId The ID of the newly created stream.
    /// @param commonParams Common parameters emitted in Create events across all Lockup models.
    /// @param tranches The tranches the protocol uses to compose the tranched distribution function.
    event CreateLockupTranchedStream(
        uint256 indexed streamId, Lockup.CreateEventCommon commonParams, LockupTranched.Tranche[] tranches
    );

    /// @notice Emitted when canceling multiple streams and one particular cancellation reverts.
    /// @param streamId The ID of the stream that reverted the cancellation.
    /// @param revertData The error data returned by the reverted cancel.
    event InvalidStreamInCancelMultiple(uint256 indexed streamId, bytes revertData);

    /// @notice Emitted when withdrawing from multiple streams and one particular withdrawal reverts.
    /// @param streamId The ID of the stream that reverted the withdrawal.
    /// @param revertData The error data returned by the reverted withdraw.
    event InvalidWithdrawalInWithdrawMultiple(uint256 indexed streamId, bytes revertData);

    /// @notice Emitted when a sender gives up the right to cancel a stream.
    /// @param streamId The ID of the stream.
    event RenounceLockupStream(uint256 indexed streamId);

    /// @notice Emitted when the comptroller sets a new NFT descriptor contract.
    /// @param comptroller The address of the current comptroller.
    /// @param oldNFTDescriptor The address of the old NFT descriptor contract.
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    event SetNFTDescriptor(
        ISablierComptroller indexed comptroller,
        ILockupNFTDescriptor indexed oldNFTDescriptor,
        ILockupNFTDescriptor indexed newNFTDescriptor
    );

    /// @notice Emitted when tokens are withdrawn from a stream.
    /// @param streamId The ID of the stream.
    /// @param to The address that has received the withdrawn tokens.
    /// @param token The contract address of the ERC-20 token that has been withdrawn.
    /// @param amount The amount of tokens withdrawn, denoted in units of the token's decimals.
    event WithdrawFromLockupStream(uint256 indexed streamId, address indexed to, IERC20 indexed token, uint128 amount);

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the stream's recipient.
    /// @dev Reverts if the NFT has been burned.
    /// @param streamId The stream ID for the query.
    function getRecipient(uint256 streamId) external view returns (address recipient);

    /// @notice Retrieves a flag indicating whether the stream is cold, i.e. settled, canceled, or depleted.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function isCold(uint256 streamId) external view returns (bool result);

    /// @notice Retrieves a flag indicating whether the stream is warm, i.e. either pending or streaming.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function isWarm(uint256 streamId) external view returns (bool result);

    /// @notice Calculates the amount that the sender would be refunded if the stream were canceled, denoted in units
    /// of the token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function refundableAmountOf(uint256 streamId) external view returns (uint128 refundableAmount);

    /// @notice Retrieves the stream's status.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function statusOf(uint256 streamId) external view returns (Lockup.Status status);

    /// @notice Calculates the amount streamed to the recipient, denoted in units of the token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    ///
    /// Notes:
    /// - Upon cancellation of the stream, the amount streamed is calculated as the difference between the deposited
    /// amount and the refunded amount. Ultimately, when the stream becomes depleted, the streamed amount is equivalent
    /// to the total amount withdrawn.
    ///
    /// @param streamId The stream ID for the query.
    function streamedAmountOf(uint256 streamId) external view returns (uint128 streamedAmount);

    /// @notice Calculates the amount that the recipient can withdraw from the stream, denoted in units of the token's
    /// decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function withdrawableAmountOf(uint256 streamId) external view returns (uint128 withdrawableAmount);

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Allows a recipient contract to hook to Sablier when a stream is canceled or when tokens are withdrawn.
    /// Useful for implementing contracts that hold streams on behalf of users, such as vaults or staking contracts.
    ///
    /// @dev Emits an {AllowToHook} event.
    ///
    /// Notes:
    /// - Does not revert if the contract is already on the allowlist.
    /// - This is an irreversible operation. The contract cannot be removed from the allowlist.
    ///
    /// Requirements:
    /// - `msg.sender` must be the comptroller contract.
    /// - `recipient` must implement {ISablierLockupRecipient}.
    ///
    /// @param recipient The address of the contract to allow for hooks.
    function allowToHook(address recipient) external;

    /// @notice Burns the NFT associated with the stream.
    ///
    /// @dev Emits a {Transfer} and {MetadataUpdate} event.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must reference a depleted stream.
    /// - The NFT must exist.
    /// - `msg.sender` must be either the NFT owner or an approved third party.
    ///
    /// @param streamId The ID of the stream NFT to burn.
    function burn(uint256 streamId) external payable;

    /// @notice Cancels the stream and refunds any remaining tokens to the sender.
    ///
    /// @dev Emits a {Transfer}, {CancelLockupStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - If there any tokens left for the recipient to withdraw, the stream is marked as canceled. Otherwise, the
    /// stream is marked as depleted.
    /// - If the address is on the allowlist, this function will invoke a hook on the recipient.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - The stream must be warm and cancelable.
    /// - `msg.sender` must be the stream's sender.
    ///
    /// @param streamId The ID of the stream to cancel.
    /// @return refundedAmount The amount refunded to the sender, denoted in units of the token's decimals.
    function cancel(uint256 streamId) external payable returns (uint128 refundedAmount);

    /// @notice Cancels multiple streams and refunds any remaining tokens to the sender.
    ///
    /// @dev Emits multiple {Transfer}, {CancelLockupStream} and {MetadataUpdate} events. For each reverted
    /// cancellation, it emits an {InvalidStreamInCancelMultiple} event.
    ///
    /// Notes:
    /// - This function as a whole will not revert if one or more cancellations revert. A zero amount is returned for
    /// reverted streams.
    /// - Refer to the notes and requirements from {cancel}.
    ///
    /// @param streamIds The IDs of the streams to cancel.
    /// @return refundedAmounts The amounts refunded to the sender, denoted in units of the token's decimals.
    function cancelMultiple(uint256[] calldata streamIds) external payable returns (uint128[] memory refundedAmounts);

    /// @notice Creates a stream by setting the start time to `block.timestamp`, and the end time to the sum of
    /// `block.timestamp` and all specified time durations. The segment timestamps are derived from these
    /// durations. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateLockupDynamicStream} and {MetadataUpdate} event.
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
        payable
        returns (uint256 streamId);

    /// @notice Creates a stream by setting the start time to `block.timestamp`, and the end time to
    /// the sum of `block.timestamp` and `durations.total`. The stream is funded by `msg.sender` and is wrapped in an
    /// ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateLockupLinearStream} and {MetadataUpdate} event.
    ///
    /// Requirements:
    /// - All requirements in {createWithTimestampsLL} must be met for the calculated parameters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {DataTypes}.
    /// @param durations Struct encapsulating (i) cliff period duration and (ii) total stream duration, both in seconds.
    /// @param unlockAmounts Struct encapsulating (i) the amount to unlock at the start time and (ii) the amount to
    /// unlock at the cliff time.
    /// @return streamId The ID of the newly created stream.
    function createWithDurationsLL(
        Lockup.CreateWithDurations calldata params,
        LockupLinear.UnlockAmounts calldata unlockAmounts,
        LockupLinear.Durations calldata durations
    )
        external
        payable
        returns (uint256 streamId);

    /// @notice Creates a stream by setting the start time to `block.timestamp`, and the end time to the sum of
    /// `block.timestamp` and all specified time durations. The tranche timestamps are derived from these
    /// durations. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateLockupTrancheStream} and {MetadataUpdate} event.
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
        payable
        returns (uint256 streamId);

    /// @notice Creates a stream with the provided segment timestamps, implying the end time from the last timestamp.
    /// The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateLockupDynamicStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - As long as the segment timestamps are arranged in ascending order, it is not an error for some
    /// of them to be in the past.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `params.depositAmount` must be greater than zero.
    /// - `params.timestamps.start` must be greater than zero and less than the first segment's timestamp.
    /// - `segments` must have at least one segment.
    /// - The segment timestamps must be arranged in ascending order.
    /// - `params.timestamps.end` must be equal to the last segment's timestamp.
    /// - The sum of the segment amounts must equal the deposit amount.
    /// - `params.recipient` must not be the zero address.
    /// - `params.sender` must not be the zero address.
    /// - `msg.sender` must have allowed this contract to spend at least `params.depositAmount` tokens.
    /// - `params.token` must not be the native token.
    /// - `params.shape.length` must not be greater than 32 characters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {DataTypes}.
    /// @param segments Segments used to compose the dynamic distribution function.
    /// @return streamId The ID of the newly created stream.
    function createWithTimestampsLD(
        Lockup.CreateWithTimestamps calldata params,
        LockupDynamic.Segment[] calldata segments
    )
        external
        payable
        returns (uint256 streamId);

    /// @notice Creates a stream with the provided start time and end time. The stream is funded by `msg.sender` and is
    /// wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateLockupLinearStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - A cliff time of zero means there is no cliff.
    /// - As long as the times are ordered, it is not an error for the start or the cliff time to be in the past.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `params.depositAmount` must be greater than zero.
    /// - `params.timestamps.start` must be greater than zero and less than `params.timestamps.end`.
    /// - If set, `cliffTime` must be greater than `params.timestamps.start` and less than
    /// `params.timestamps.end`.
    /// - `params.recipient` must not be the zero address.
    /// - `params.sender` must not be the zero address.
    /// - The sum of `params.unlockAmounts.start` and `params.unlockAmounts.cliff` must be less than or equal to
    /// deposit amount.
    /// - If `params.timestamps.cliff` not set, the `params.unlockAmounts.cliff` must be zero.
    /// - `msg.sender` must have allowed this contract to spend at least `params.depositAmount` tokens.
    /// - `params.token` must not be the native token.
    /// - `params.shape.length` must not be greater than 32 characters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {DataTypes}.
    /// @param cliffTime The Unix timestamp for the cliff period's end. A value of zero means there is no cliff.
    /// @param unlockAmounts Struct encapsulating (i) the amount to unlock at the start time and (ii) the amount to
    /// unlock at the cliff time.
    /// @return streamId The ID of the newly created stream.
    function createWithTimestampsLL(
        Lockup.CreateWithTimestamps calldata params,
        LockupLinear.UnlockAmounts calldata unlockAmounts,
        uint40 cliffTime
    )
        external
        payable
        returns (uint256 streamId);

    /// @notice Creates a stream with the provided tranche timestamps, implying the end time from the last timestamp.
    /// The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateLockupTrancheStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - As long as the tranche timestamps are arranged in ascending order, it is not an error for some
    /// of them to be in the past.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `params.depositAmount` must be greater than zero.
    /// - `params.timestamps.start` must be greater than zero and less than the first tranche's timestamp.
    /// - `tranches` must have at least one tranche.
    /// - The tranche timestamps must be arranged in ascending order.
    /// - `params.timestamps.end` must be equal to the last tranche's timestamp.
    /// - The sum of the tranche amounts must equal the deposit amount.
    /// - `params.recipient` must not be the zero address.
    /// - `params.sender` must not be the zero address.
    /// - `msg.sender` must have allowed this contract to spend at least `params.depositAmount` tokens.
    /// - `params.token` must not be the native token.
    /// - `params.shape.length` must not be greater than 32 characters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {DataTypes}.
    /// @param tranches Tranches used to compose the tranched distribution function.
    /// @return streamId The ID of the newly created stream.
    function createWithTimestampsLT(
        Lockup.CreateWithTimestamps calldata params,
        LockupTranched.Tranche[] calldata tranches
    )
        external
        payable
        returns (uint256 streamId);

    /// @notice Recover the surplus amount of tokens.
    ///
    /// @dev Notes:
    /// - The surplus amount is defined as the difference between the total balance of the contract for the provided
    /// ERC-20 token and the sum of balances of all streams created using the same ERC-20 token.
    ///
    /// Requirements:
    /// - `msg.sender` must be the comptroller contract.
    /// - The surplus amount must be greater than zero.
    ///
    /// @param token The contract address of the ERC-20 token to recover for.
    /// @param to The address to send the surplus amount.
    function recover(IERC20 token, address to) external;

    /// @notice Removes the right of the stream's sender to cancel the stream.
    ///
    /// @dev Emits a {RenounceLockupStream} event.
    ///
    /// Notes:
    /// - This is an irreversible operation.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must reference a warm stream.
    /// - `msg.sender` must be the stream's sender.
    /// - The stream must be cancelable.
    ///
    /// @param streamId The ID of the stream to renounce.
    function renounce(uint256 streamId) external payable;

    /// @notice Sets the native token address. Once set, it cannot be changed.
    /// @dev For more information, see the documentation for {nativeToken}.
    ///
    /// Notes:
    /// - If `newNativeToken` is zero address, the function does not revert.
    ///
    /// Requirements:
    /// - `msg.sender` must be the comptroller contract.
    /// - The current native token must be zero address.
    /// @param newNativeToken The address of the native token.
    function setNativeToken(address newNativeToken) external;

    /// @notice Sets a new NFT descriptor contract, which produces the URI describing the Sablier stream NFTs.
    ///
    /// @dev Emits a {SetNFTDescriptor} and {BatchMetadataUpdate} event.
    ///
    /// Notes:
    /// - Does not revert if the NFT descriptor is the same.
    ///
    /// Requirements:
    /// - `msg.sender` must be the comptroller contract.
    ///
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    function setNFTDescriptor(ILockupNFTDescriptor newNFTDescriptor) external;

    /// @notice Withdraws the provided amount of tokens from the stream to the `to` address.
    ///
    /// @dev Emits a {Transfer}, {WithdrawFromLockupStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - If `msg.sender` is not the recipient and the address is on the allowlist, this function will invoke a hook on
    /// the recipient.
    /// - The minimum fee in wei is calculated for the stream's sender using the {SablierComptroller} contract.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null or depleted stream.
    /// - `to` must not be the zero address.
    /// - `amount` must be greater than zero and must not exceed the withdrawable amount.
    /// - `to` must be the recipient if `msg.sender` is not the stream's recipient or an approved third party.
    /// - `msg.value` must be greater than or equal to the minimum fee in wei for the stream's sender.
    ///
    /// @param streamId The ID of the stream to withdraw from.
    /// @param to The address receiving the withdrawn tokens.
    /// @param amount The amount to withdraw, denoted in units of the token's decimals.
    function withdraw(uint256 streamId, address to, uint128 amount) external payable;

    /// @notice Withdraws the maximum withdrawable amount from the stream to the provided address `to`.
    ///
    /// @dev Emits a {Transfer}, {WithdrawFromLockupStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - Refer to the notes in {withdraw}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {withdraw}.
    ///
    /// @param streamId The ID of the stream to withdraw from.
    /// @param to The address receiving the withdrawn tokens.
    /// @return withdrawnAmount The amount withdrawn, denoted in units of the token's decimals.
    function withdrawMax(uint256 streamId, address to) external payable returns (uint128 withdrawnAmount);

    /// @notice Withdraws the maximum withdrawable amount from the stream to the current recipient, and transfers the
    /// NFT to `newRecipient`.
    ///
    /// @dev Emits a {WithdrawFromLockupStream}, {Transfer} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - If the withdrawable amount is zero, the withdrawal is skipped.
    /// - Refer to the notes in {withdraw}.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the NFT owner or an approved third party.
    /// - Refer to the requirements in {withdraw}.
    /// - Refer to the requirements in {IERC721.transferFrom}.
    ///
    /// @param streamId The ID of the stream NFT to transfer.
    /// @param newRecipient The address of the new owner of the stream NFT.
    /// @return withdrawnAmount The amount withdrawn, denoted in units of the token's decimals.
    function withdrawMaxAndTransfer(
        uint256 streamId,
        address newRecipient
    )
        external
        payable
        returns (uint128 withdrawnAmount);

    /// @notice Withdraws tokens from streams to the recipient of each stream.
    ///
    /// @dev Emits multiple {Transfer}, {WithdrawFromLockupStream} and {MetadataUpdate} events. For each reverting
    /// withdrawal, it emits an {InvalidWithdrawalInWithdrawMultiple} event.
    ///
    /// Notes:
    /// - This function as a whole will not revert if one or more withdrawals revert.
    /// - This function attempts to call a hook on the recipient of each stream, unless `msg.sender` is the recipient.
    /// - Refer to the notes and requirements from {withdraw}.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - There must be an equal number of `streamIds` and `amounts`.
    ///
    /// @param streamIds The IDs of the streams to withdraw from.
    /// @param amounts The amounts to withdraw, denoted in units of the token's decimals.
    function withdrawMultiple(uint256[] calldata streamIds, uint128[] calldata amounts) external payable;
}
