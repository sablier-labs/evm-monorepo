// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IERC721Metadata } from "@openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Lockup } from "../types/DataTypes.sol";
import { ISablierV2Config } from "./ISablierV2Config.sol";
import { ISablierV2Comptroller } from "./ISablierV2Comptroller.sol";

/// @title ISablierV2Lockup
/// @notice The common interface between all Sablier V2 lockup streaming contracts.
interface ISablierV2Lockup is
    ISablierV2Config, // no dependencies
    IERC721Metadata // two dependencies
{
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Queries the address of the ERC-20 asset used for streaming.
    /// @param streamId The id of the stream to make the query for.
    /// @return asset The contract address of the ERC-20 asset used for streaming.
    function getAsset(uint256 streamId) external view returns (IERC20 asset);

    /// @notice Queries the amount deposited in the stream, in units of the asset's decimals.
    /// @param streamId The id of the stream to make the query for.
    function getDepositAmount(uint256 streamId) external view returns (uint128 depositAmount);

    /// @notice Queries the end time of the stream.
    /// @param streamId The id of the stream to make the query for.
    function getEndTime(uint256 streamId) external view returns (uint40 endTime);

    /// @notice Queries the recipient of the stream.
    /// @param streamId The id of the stream to make the query for.
    function getRecipient(uint256 streamId) external view returns (address recipient);

    /// @notice Queries the sender of the stream.
    /// @param streamId The id of the stream to make the query for.
    function getSender(uint256 streamId) external view returns (address sender);

    /// @notice Queries the start time of the stream.
    /// @param streamId The id of the stream to make the query for.
    function getStartTime(uint256 streamId) external view returns (uint40 startTime);

    /// @notice Queries the status of the stream.
    /// @param streamId The id of the stream to make the query for.
    function getStatus(uint256 streamId) external view returns (Lockup.Status status);

    /// @notice Queries the amount withdrawn from the stream, in units of the asset's decimals.
    /// @param streamId The id of the stream to make the query for.
    function getWithdrawnAmount(uint256 streamId) external view returns (uint128 withdrawnAmount);

    /// @notice Checks whether the stream is cancelable or not.
    ///
    /// Notes:
    /// - Always returns `false` if the stream is not active.
    ///
    /// @param streamId The id of the stream to make the query for.
    function isCancelable(uint256 streamId) external view returns (bool result);

    /// @notice Calculates the amount that the sender would be returned if the stream was canceled, in units of the
    /// asset's decimals.
    /// @param streamId The id of the stream to make the query for.
    function returnableAmountOf(uint256 streamId) external view returns (uint128 returnableAmount);

    /// @notice Calculates the amount that has been streamed to the recipient, in units of the asset's decimals.
    /// @param streamId The id of the stream to make the query for.
    function streamedAmountOf(uint256 streamId) external view returns (uint128 streamedAmount);

    /// @notice Calculates the amount that the recipient can withdraw from the stream, in units of the asset's decimals.
    /// @param streamId The id of the stream to make the query for.
    function withdrawableAmountOf(uint256 streamId) external view returns (uint128 withdrawableAmount);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Burns the NFT associated with the stream.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Notes:
    /// - The purpose of this function is to make the integration of Sablier V2 easier. Third-party contracts don't
    /// have to constantly check for the existence of the NFT. They can decide to burn the NFT themselves, or not.
    ///
    /// Requirements:
    /// - `streamId` must point to a stream that is either canceled or depleted.
    /// - The NFT must exist.
    /// - `msg.sender` must be either an approved operator or the owner of the NFT.
    ///
    /// @param streamId The id of the stream NFT to burn.
    function burn(uint256 streamId) external;

    /// @notice Cancels multiple streams and. for each stream, transfers any remaining assets to the sender and
    /// the recipient.
    ///
    /// @dev Emits a {CancelLockupStream} event.
    ///
    /// Notes:
    /// - This function will attempt to call a hook on either the sender or the recipient, depending upon who the
    /// `msg.sender` is, and if the sender and the recipient are contracts.
    ///
    /// Requirements:
    /// - `streamId` must point to an active stream.
    /// - `msg.sender` must be either the sender of the stream or the recipient of the stream (also known as the
    /// the owner of the NFT).
    /// - The stream must be cancelable.
    ///
    /// @param streamId The id of the stream to cancel.
    function cancel(uint256 streamId) external;

    /// @notice Cancels multiple streams and transfers any remaining assets to the sender and the recipient.
    ///
    /// @dev Emits multiple {CancelLockupStream} events.
    ///
    /// Notes:
    /// - It is not an error if one of the stream ids points to a stream that is not active or is active but
    /// is not cancelable.
    /// - This function will attempt to call a hook on either the sender or the recipient of each stream.
    ///
    /// Requirements:
    /// - Each stream id in `streamIds` must point to an active stream.
    /// - `msg.sender` must be either the sender of the stream or the recipient of the stream (also known as the
    /// owner of the NFT) of every stream.
    /// - Each stream must be cancelable.
    ///
    /// @param streamIds The ids of the streams to cancel.
    function cancelMultiple(uint256[] calldata streamIds) external;

    /// @notice Counter for stream ids.
    /// @return The next stream id.
    function nextStreamId() external view returns (uint256);

    /// @notice Makes the stream non-cancelable. This is an irreversible operation.
    ///
    /// @dev Emits a {RenounceLockupStream} event.
    ///
    /// Requirements:
    /// - `streamId` must point to an active stream.
    /// - `msg.sender` must be the sender.
    /// - The stream must not be already non-cancelable.
    ///
    /// @param streamId The id of the stream to renounce.
    function renounce(uint256 streamId) external;

    /// @notice Withdraws the provided amount of assets from the stream to the provided address `to`.
    ///
    /// @dev Emits a {WithdrawFromLockupStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - This function will attempt to call a hook on the recipient of the stream, if the recipient is a contract.
    ///
    /// Requirements:
    /// - `streamId` must point to an active stream.
    /// - `msg.sender` must be the sender of the stream, an approved operator, or the owner of the NFT (also known
    /// as the recipient of the stream).
    /// - `to` must be the recipient if `msg.sender` is the sender of the stream.
    /// - `amount` must not be zero and must not exceed the withdrawable amount.
    ///
    /// @param streamId The id of the stream to withdraw.
    /// @param to The address that receives the withdrawn assets.
    /// @param amount The amount to withdraw, in units of the asset's decimals.
    function withdraw(uint256 streamId, address to, uint128 amount) external;

    /// @notice Withdraws the maximum withdrawable amount from the stream to the provided address `to`.
    ///
    /// @dev Emits a {WithdrawFromLockupStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - All from {withdraw}.
    ///
    /// Requirements:
    /// - All from {withdraw}.
    ///
    /// @param streamId The id of the stream to withdraw.
    /// @param to The address that receives the withdrawn assets.
    function withdrawMax(uint256 streamId, address to) external;

    /// @notice Withdraws assets from multiple streams to the provided address `to`.
    ///
    /// @dev Emits multiple {WithdrawFromLockupStream} and {Transfer} events.
    ///
    /// Notes:
    /// - It is not an error if one of the stream ids points to a stream that is not active.
    /// - This function will attempt to call a hook on the recipient of each stream.
    ///
    /// Requirements:
    /// - The count of `streamIds` must match the count of `amounts`.
    /// - `msg.sender` must be either the recipient of the stream (a.k.a the owner of the NFT) or an approved operator.
    /// - Each amount in `amounts` must not be zero and must not exceed the withdrawable amount.
    ///
    /// @param streamIds The ids of the streams to withdraw.
    /// @param to The address that receives the withdrawn assets, if the `msg.sender` is not the stream sender.
    /// @param amounts The amounts to withdraw, in units of the asset's decimals.
    function withdrawMultiple(uint256[] calldata streamIds, address to, uint128[] calldata amounts) external;
}
