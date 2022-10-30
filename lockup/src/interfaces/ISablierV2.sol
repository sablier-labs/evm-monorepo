// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ISablierV2
/// @notice The common interface between all Sablier V2 streaming contracts.
/// @author Sablier Labs Ltd.
interface ISablierV2 is IERC721 {
    /*//////////////////////////////////////////////////////////////////////////
                                    CUSTOM ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when attempting to create a stream with a zero deposit amount.
    error SablierV2__DepositAmountZero();

    /// @notice Emitted when attempting to create a stream with the recipient as the zero address.
    error SablierV2__RecipientZeroAddress();

    /// @notice Emitted when attempting to renounce an already non-cancelable stream.
    error SablierV2__RenounceNonCancelableStream(uint256 streamId);

    /// @notice Emitted when attempting to create a stream with the sender as the zero address.
    error SablierV2__SenderZeroAddress();

    /// @notice Emitted when attempting to create a stream with the start time greater than the stop time.
    error SablierV2__StartTimeGreaterThanStopTime(uint64 startTime, uint64 stopTime);

    /// @notice Emitted when attempting to cancel a stream that is already non-cancelable.
    error SablierV2__StreamNonCancelable(uint256 streamId);

    /// @notice Emitted when the stream id points to a nonexistent stream.
    error SablierV2__StreamNonExistent(uint256 streamId);

    /// @notice Emitted when the caller is not authorized to perform some action.
    error SablierV2__Unauthorized(uint256 streamId, address caller);

    /// @notice Emitted when attempting to withdraw from multiple streams and the count of the stream ids does
    /// not match the count of the amounts.
    error SablierV2__WithdrawAllArraysNotEqual(uint256 streamIdsLength, uint256 amountsLength);

    /// @notice Emitted when attempting to withdraw more than can be withdrawn.
    error SablierV2__WithdrawAmountGreaterThanWithdrawableAmount(
        uint256 streamId,
        uint256 withdrawAmount,
        uint256 withdrawableAmount
    );

    /// @notice Emitted when attempting to withdraw zero tokens from a stream.
    /// @notice The id of the stream.
    error SablierV2__WithdrawAmountZero(uint256 streamId);

    /// @notice Emitted when attempting to withdraw to a zero address.
    error SablierV2__WithdrawZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a stream is canceled.
    /// @param streamId The id of the stream.
    /// @param recipient The address of the recipient.
    /// @param withdrawAmount The amount of tokens withdrawn to the recipient, in units of the token's decimals.
    /// @param returnAmount The amount of tokens returned to the sender, in units of the token's decimals.
    event Cancel(uint256 indexed streamId, address indexed recipient, uint256 withdrawAmount, uint256 returnAmount);

    /// @notice Emitted when a sender makes a stream non-cancelable.
    /// @param streamId The id of the stream.
    event Renounce(uint256 indexed streamId);

    /// @notice Emitted when tokens are withdrawn from a stream.
    /// @param streamId The id of the stream.
    /// @param to The address that will receive the withdrawn tokens.
    /// @param amount The amount of tokens withdrawn, in units of the token's decimals.
    event Withdraw(uint256 indexed streamId, address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Reads the amount deposited in the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return depositAmount The amount deposited in the stream, in units of the ERC-20 token's decimals.
    function getDepositAmount(uint256 streamId) external view returns (uint256 depositAmount);

    /// @notice Reads the recipient of the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return recipient The recipient of the stream.
    function getRecipient(uint256 streamId) external view returns (address recipient);

    /// @notice Calculates the amount that the sender would be returned if the stream was canceled.
    /// @param streamId The id of the stream to make the query for.
    /// @return returnableAmount The amount of tokens that would be returned if the stream was canceled, in units of
    /// the ERC-20 token's decimals.
    function getReturnableAmount(uint256 streamId) external view returns (uint256 returnableAmount);

    /// @notice Reads the sender of the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return sender The sender of the stream.
    function getSender(uint256 streamId) external view returns (address sender);

    /// @notice Reads the start time of the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return startTime The start time of the stream.
    function getStartTime(uint256 streamId) external view returns (uint64 startTime);

    /// @notice Reads the stop time of the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return stopTime The stop time of the stream.
    function getStopTime(uint256 streamId) external view returns (uint64 stopTime);

    /// @notice Calculates the amount that the recipient can withdraw from the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return withdrawableAmount The amount of tokens that the recipient can withdraw from the stream, in units of
    /// the ERC-20 token's decimals.
    function getWithdrawableAmount(uint256 streamId) external view returns (uint256 withdrawableAmount);

    /// @notice Reads the amount withdrawn from the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return withdrawnAmount The amount withdrawn from the stream, in units of the ERC-20 token's decimals.
    function getWithdrawnAmount(uint256 streamId) external view returns (uint256 withdrawnAmount);

    /// @notice Checks whether the stream is cancelable or not.
    /// @param streamId The id of the stream to make the query for.
    /// @return cancelable Whether the stream is cancelable or not.
    function isCancelable(uint256 streamId) external view returns (bool cancelable);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Cancels the stream and transfers any remaining amounts to the sender and the recipient.
    ///
    /// @dev Emits a {Cancel} event.
    ///
    /// Requiremenets:
    /// - `streamId` must point to an existent stream.
    /// - `msg.sender` must be either the sender or recipient.
    /// - The stream must be cancelable.
    ///
    /// @param streamId The id of the stream to cancel.
    function cancel(uint256 streamId) external;

    /// @notice Cancels multiple streams and transfers any remaining amounts to the sender and the recipient.
    ///
    /// @dev Emits multiple {Cancel} events.
    ///
    /// Requiremenets:
    /// - Each stream id in `streamIds` must point to an existent stream.
    /// - `msg.sender` must be either the sender or recipient of every stream.
    /// - Each stream must be cancelable.
    ///
    /// @param streamIds The ids of the streams to cancel.
    function cancelAll(uint256[] calldata streamIds) external;

    /// @notice Counter for stream ids.
    /// @return The next stream id.
    function nextStreamId() external view returns (uint256);

    /// @notice Makes the stream non-cancelable.
    ///
    /// @dev Emits a {Renounce} event.
    ///
    /// Requiremenets:
    /// - `streamId` must point to an existent stream.
    /// - `msg.sender` must be the sender.
    /// - The stream must not be already non-cancelable.
    ///
    /// @param streamId The id of the stream to renounce.
    function renounce(uint256 streamId) external;

    /// @notice Withdraws tokens from the stream to the recipient's account.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// Requirements:
    /// - `streamId` must point to an existent stream.
    /// - `msg.sender` must be either the sender or recipient.
    /// - `amount` must not be zero and must not exceed the withdrawable amount.
    ///
    /// @param streamId The id of the stream to withdraw.
    /// @param amount The amount to withdraw, in units of the ERC-20 token's decimals.
    function withdraw(uint256 streamId, uint256 amount) external;

    /// @notice Withdraws tokens from multiple streams to the recipient's account.
    ///
    /// @dev Emits multiple {Withdraw} event.
    ///
    /// Requirements:
    /// - The count of `streamIds` must match the count of `amounts`.
    /// - `msg.sender` must be either the sender or recipient of every stream.
    /// - Each stream id in `streamIds` must point to an existent stream.
    /// - Each amount in `amounts` must not be zero and must not exceed the withdrawable amount.
    ///
    /// @param streamIds The ids of the streams to withdraw.
    /// @param amounts The amounts to withdraw, in units of the ERC-20 token's decimals.
    function withdrawAll(uint256[] calldata streamIds, uint256[] calldata amounts) external;

    /// @notice Withdraws tokens from multiple streams to the provided address `to`.
    ///
    /// @dev Emits multiple {Withdraw} event.
    ///
    /// Requirements:
    /// - `to` must not be the zero address.
    /// - The count of `streamIds` must match the count of `amounts`.
    /// - Each stream id in `streamIds` must point to an existent stream.
    /// - `msg.sender` must be the recipient of every stream.
    /// - Each amount in `amounts` must not be zero and must not exceed the withdrawable amount.
    ///
    /// @param streamIds The ids of the streams to withdraw.
    /// @param to The address that will receive the withdrawn tokens.
    /// @param amounts The amounts to withdraw, in units of the ERC-20 token's decimals.
    function withdrawAllTo(
        uint256[] calldata streamIds,
        address to,
        uint256[] calldata amounts
    ) external;

    /// @notice Withdraws tokens from the stream to the provided address `to`.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// Requirements:
    /// - `streamId` must point to an existent stream.
    /// - `to` must not be the zero address.
    /// - `msg.sender` must be the recipient.
    /// - `amount` must not be zero and must not exceed the withdrawable amount.
    ///
    /// @param streamId The id of the stream to withdraw.
    /// @param to The address that will receive the withdrawn tokens.
    /// @param amount The amount to withdraw, in units of the ERC-20 token's decimals.
    function withdrawTo(
        uint256 streamId,
        address to,
        uint256 amount
    ) external;
}
