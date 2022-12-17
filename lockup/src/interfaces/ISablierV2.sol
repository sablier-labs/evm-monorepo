// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ISablierV2
/// @notice The common interface between all Sablier V2 streaming contracts.
interface ISablierV2 is IERC721 {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Reads the amount deposited in the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return depositAmount The amount deposited in the stream, in units of the ERC-20 token's decimals.
    function getDepositAmount(uint256 streamId) external view returns (uint128 depositAmount);

    /// @notice Reads the recipient of the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return recipient The recipient of the stream.
    function getRecipient(uint256 streamId) external view returns (address recipient);

    /// @notice Calculates the amount that the sender would be returned if the stream was canceled.
    /// @param streamId The id of the stream to make the query for.
    /// @return returnableAmount The amount of tokens that would be returned if the stream was canceled, in units of
    /// the ERC-20 token's decimals.
    function getReturnableAmount(uint256 streamId) external view returns (uint128 returnableAmount);

    /// @notice Reads the sender of the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return sender The sender of the stream.
    function getSender(uint256 streamId) external view returns (address sender);

    /// @notice Reads the start time of the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return startTime The start time of the stream.
    function getStartTime(uint256 streamId) external view returns (uint40 startTime);

    /// @notice Reads the stop time of the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return stopTime The stop time of the stream.
    function getStopTime(uint256 streamId) external view returns (uint40 stopTime);

    /// @notice Calculates the amount that the recipient can withdraw from the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return withdrawableAmount The amount of tokens that the recipient can withdraw from the stream, in units of
    /// the ERC-20 token's decimals.
    function getWithdrawableAmount(uint256 streamId) external view returns (uint128 withdrawableAmount);

    /// @notice Reads the amount withdrawn from the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return withdrawnAmount The amount withdrawn from the stream, in units of the ERC-20 token's decimals.
    function getWithdrawnAmount(uint256 streamId) external view returns (uint128 withdrawnAmount);

    /// @notice Checks whether the stream is cancelable or not.
    /// @param streamId The id of the stream to make the query for.
    /// @return result Whether the stream is cancelable or not.
    function isCancelable(uint256 streamId) external view returns (bool result);

    /// @notice Checks whether the stream entity exists or not.
    /// @param streamId The id of the stream to make the query for.
    /// @return result Whether the stream entity exists or not.
    function isEntity(uint256 streamId) external view returns (bool result);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Burns the NFT associated with the stream.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// The purpose of this function is to make the integration of Sablier V2 easier. Because the burning of
    /// the NFT is separated from the deletion of the stream entity from the mapping, third-party contracts don't
    /// have to constantly check for the existence of the NFT. They can decide to burn the NFT themselves, or not.
    ///
    /// Requirements:
    /// - `streamId` must point to a deleted stream.
    /// - The NFT must exist.
    /// - `msg.sender` must be either an approved operator or the owner of the NFT.
    ///
    /// @param streamId The id of the stream NFT to burn.
    function burn(uint256 streamId) external;

    /// @notice Cancels the stream and transfers any remaining amounts to the sender and the recipient.
    ///
    /// @dev Emits a {Cancel} event.
    ///
    /// This function will attempt to call a hook on either the sender or the recipient, depending upon who is
    /// the caller, and if the sender and the recipient are contracts.
    ///
    /// Requirements:
    /// - `streamId` must point to an existent stream.
    /// - `msg.sender` must be either the sender of the stream or the owner of the NFT (also known as the
    /// recipient of the stream).
    /// - The stream must be cancelable.
    ///
    /// @param streamId The id of the stream to cancel.
    function cancel(uint256 streamId) external;

    /// @notice Cancels multiple streams and transfers any remaining amounts to the sender and the recipient.
    ///
    /// @dev Emits multiple {Cancel} events.
    ///
    /// Requirements:
    /// - Each stream id in `streamIds` must point to an existent stream.
    /// - `msg.sender` must be either the sender of the stream or the owner of the NFT (also known as the
    /// recipient of the stream) of every stream.
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
    /// Requirements:
    /// - `streamId` must point to an existent stream.
    /// - `msg.sender` must be the sender.
    /// - The stream must not be already non-cancelable.
    ///
    /// @param streamId The id of the stream to renounce.
    function renounce(uint256 streamId) external;

    /// @notice Withdraws tokens from the stream to the recipient's account.
    ///
    /// @dev Emits a {Withdraw} and a {Transfer} event.
    ///
    /// This function will attempt to call a hook on the recipient of the stream, if the recipient is a contract.
    ///
    /// Requirements:
    /// - `streamId` must point to an existent stream.
    /// - `msg.sender` must be the sender of the stream, an approved operator, or the owner of the
    /// NFT (also known as the recipient of the stream).
    /// - `amount` must not be zero and must not exceed the withdrawable amount.
    ///
    /// @param streamId The id of the stream to withdraw.
    /// @param amount The amount to withdraw, in units of the ERC-20 token's decimals.
    function withdraw(uint256 streamId, uint128 amount) external;

    /// @notice Withdraws tokens from multiple streams to the recipient's account.
    ///
    /// @dev Emits multiple {Withdraw} and {Transfer} events.
    ///
    /// This function will attempt to call a hook on the recipient of each stream, if the recipient is a contract.
    ///
    /// Requirements:
    /// - The count of `streamIds` must match the count of `amounts`.
    /// - `msg.sender` must be the sender of the stream, an approved operator, or the owner of the
    /// NFT (also known as the recipient of the stream) of every stream.
    /// - Each stream id in `streamIds` must point to an existent stream.
    /// - Each amount in `amounts` must not be zero and must not exceed the withdrawable amount.
    ///
    /// @param streamIds The ids of the streams to withdraw.
    /// @param amounts The amounts to withdraw, in units of the ERC-20 token's decimals.
    function withdrawAll(uint256[] calldata streamIds, uint128[] calldata amounts) external;

    /// @notice Withdraws tokens from multiple streams to the provided address `to`.
    ///
    /// @dev Emits multiple {Withdraw} and {Transfer} events.
    ///
    /// This function will attempt to call a hook on the recipient of each stream, if the recipient is a contract.
    ///
    /// Requirements:
    /// - `to` must not be the zero address.
    /// - The count of `streamIds` must match the count of `amounts`.
    /// - Each stream id in `streamIds` must point to an existent stream.
    /// - `msg.sender` must be an approved operator, or the owner of the NFT (also known
    /// as the recipient of the stream) of every stream.
    /// - Each amount in `amounts` must not be zero and must not exceed the withdrawable amount.
    ///
    /// @param streamIds The ids of the streams to withdraw.
    /// @param to The address that will receive the withdrawn tokens.
    /// @param amounts The amounts to withdraw, in units of the ERC-20 token's decimals.
    function withdrawAllTo(
        uint256[] calldata streamIds,
        address to,
        uint128[] calldata amounts
    ) external;

    /// @notice Withdraws tokens from the stream to the provided address `to`.
    ///
    /// @dev Emits a {Withdraw} and a {Transfer} event.
    ///
    /// This function will attempt to call a hook on the recipient of the stream, if the recipient is a contract.
    ///
    /// Requirements:
    /// - `streamId` must point to an existent stream.
    /// - `to` must not be the zero address.
    /// - `msg.sender` must be an approved operator, or the owner of the NFT (also known
    /// as the recipient of the stream).
    /// - `amount` must not be zero and must not exceed the withdrawable amount.
    ///
    /// @param streamId The id of the stream to withdraw.
    /// @param to The address that will receive the withdrawn tokens.
    /// @param amount The amount to withdraw, in units of the ERC-20 token's decimals.
    function withdrawTo(
        uint256 streamId,
        address to,
        uint128 amount
    ) external;
}
