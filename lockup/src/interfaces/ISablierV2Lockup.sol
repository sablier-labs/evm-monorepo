// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IERC721Metadata } from "@openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";

import { Lockup } from "../types/DataTypes.sol";
import { ISablierV2Base } from "./ISablierV2Base.sol";
import { ISablierV2NFTDescriptor } from "./ISablierV2NFTDescriptor.sol";

/// @title ISablierV2Lockup
/// @notice The common interface between all Sablier V2 lockup streaming contracts.
interface ISablierV2Lockup is
    ISablierV2Base, // no dependencies
    IERC721Metadata // two dependencies
{
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a lockup stream is canceled.
    /// @param streamId The id of the lockup stream.
    /// @param sender The address of the stream's sender.
    /// @param recipient The address of the stream's recipient.
    /// @param senderAmount The amount of assets returned to the sender, denoted in units of the asset's decimals.
    /// @param recipientAmount The amount of assets left to be withdrawn by the recipient, denoted in units of the
    /// asset's decimals.
    event CancelLockupStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint128 senderAmount,
        uint128 recipientAmount
    );

    /// @notice Emitted when a sender makes a lockup stream non-cancelable.
    /// @param streamId The id of the lockup stream.
    event RenounceLockupStream(uint256 indexed streamId);

    /// @notice Emitted when the contract admin sets the NFT descriptor contract.
    /// @param admin The address of the current contract admin.
    /// @param oldNFTDescriptor The address of the old NFT descriptor contract.
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    event SetNFTDescriptor(
        address indexed admin, ISablierV2NFTDescriptor oldNFTDescriptor, ISablierV2NFTDescriptor newNFTDescriptor
    );

    /// @notice Emitted when assets are withdrawn from a lockup stream.
    /// @param streamId The id of the lockup stream.
    /// @param to The address that has received the withdrawn assets.
    /// @param amount The amount of assets withdrawn, denoted in units of the asset's decimals.
    event WithdrawFromLockupStream(uint256 indexed streamId, address indexed to, uint128 amount);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Queries the address of the ERC-20 asset used for streaming.
    /// @dev Reverts if `streamId` points to a null stream.
    /// @param streamId The id of the lockup stream to make the query for.
    /// @return asset The contract address of the ERC-20 asset used for streaming.
    function getAsset(uint256 streamId) external view returns (IERC20 asset);

    /// @notice Queries the amount deposited in the lockup stream, denoted in units of the asset's decimals.
    /// @dev Reverts if `streamId` points to a null stream.
    /// @param streamId The id of the lockup stream to make the query for.
    function getDepositedAmount(uint256 streamId) external view returns (uint128 depositedAmount);

    /// @notice Queries the end time of the lockup stream.
    /// @dev Reverts if `streamId` points to a null stream.
    /// @param streamId The id of the lockup stream to make the query for.
    function getEndTime(uint256 streamId) external view returns (uint40 endTime);

    /// @notice Queries the recipient of the lockup stream.
    /// @dev Reverts if the NFT has been burned.
    /// @param streamId The id of the lockup stream to make the query for.
    function getRecipient(uint256 streamId) external view returns (address recipient);

    /// @notice Queries the amount returned to the sender, denoted in units of the asset's decimals. Unless the stream
    /// is canceled, this amount is always zero.
    /// @dev Reverts if `streamId` points to a null stream.
    /// @param streamId The id of the lockup stream to make the query for.
    function getReturnedAmount(uint256 streamId) external view returns (uint128 returnedAmount);

    /// @notice Queries the sender of the lockup stream.
    /// @dev Reverts if `streamId` points to a null stream.
    /// @param streamId The id of the lockup stream to make the query for.
    function getSender(uint256 streamId) external view returns (address sender);

    /// @notice Queries the start time of the lockup stream.
    /// @dev Reverts if `streamId` points to a null stream.
    /// @param streamId The id of the lockup stream to make the query for.
    function getStartTime(uint256 streamId) external view returns (uint40 startTime);

    /// @notice Queries the status of the lockup stream.
    /// @param streamId The id of the lockup stream to make the query for.
    function getStatus(uint256 streamId) external view returns (Lockup.Status status);

    /// @notice Queries the amount withdrawn from the lockup stream, denoted in units of the asset's decimals.
    /// @dev Reverts if `streamId` points to a null stream.
    /// @param streamId The id of the lockup stream to make the query for.
    function getWithdrawnAmount(uint256 streamId) external view returns (uint128 withdrawnAmount);

    /// @notice Checks whether the stream is cancelable or not. Always returns `false` when the stream is not active.
    /// @dev Reverts if `streamId` points to a null stream.
    /// @param streamId The id of the lockup stream to make the query for.
    function isCancelable(uint256 streamId) external view returns (bool result);

    /// @notice Counter for stream ids, used in the create functions.
    function nextStreamId() external view returns (uint256);

    /// @notice Calculates the amount that the sender would be paid if the lockup stream were to be canceled, denoted
    /// in units of the asset's decimals.
    /// @dev Reverts if `streamId` points to a null stream.
    /// @param streamId The id of the lockup stream to make the query for.
    function returnableAmountOf(uint256 streamId) external view returns (uint128 returnableAmount);

    /// @notice Calculates the amount that has been streamed to the recipient, denoted in units of the asset's decimals.
    /// @dev Reverts if `streamId` points to a null stream.
    /// @param streamId The id of the lockup stream to make the query for.
    function streamedAmountOf(uint256 streamId) external view returns (uint128 streamedAmount);

    /// @notice Calculates the amount that the recipient can withdraw from the stream, denoted in units of the asset's
    /// decimals.
    /// @dev Reverts if `streamId` points to a null stream.
    /// @param streamId The id of the lockup stream to make the query for.
    function withdrawableAmountOf(uint256 streamId) external view returns (uint128 withdrawableAmount);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Burns the NFT associated with the lockup stream.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Notes:
    /// - The purpose of this function is to make the integration of Sablier V2 easier. Third-party contracts don't
    /// have to constantly check for the existence of the NFT. They can decide to burn the NFT themselves, or not.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - `streamId` must point to a lockup stream that is depleted.
    /// - The NFT must exist.
    /// - `msg.sender` must be either the NFT owner or an approved third party.
    ///
    /// @param streamId The id of the lockup stream NFT to burn.
    function burn(uint256 streamId) external;

    /// @notice Cancels the lockup stream and transfers any remaining assets to the sender.
    ///
    /// @dev Emits a {CancelLockupStream} event and a {Transfer} event.
    ///
    /// Notes:
    /// - This function will attempt to call a hook on either the sender or the recipient, depending upon who
    /// `msg.sender` is, and if the resolved address is a contract.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - The stream must be active and cancelable.
    /// - `msg.sender` must be either the sender or the recipient of the stream (a.k.a the NFT owner).
    ///
    /// @param streamId The id of the lockup stream to cancel.
    function cancel(uint256 streamId) external;

    /// @notice Cancels multiple lockup streams and transfers any remaining assets to the sender.
    ///
    /// @dev Emits multiple {CancelLockupStream} and {Transfer} events.
    ///
    /// Notes:
    /// - This function will attempt to call a hook on either the sender or the recipient of each stream.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - Each value in `streamIds` must point to a lockup stream that is active or cancelable.
    /// - `msg.sender` must be either the sender or the recipient of each stream.
    ///
    /// @param streamIds The ids of the lockup streams to cancel.
    function cancelMultiple(uint256[] calldata streamIds) external;

    /// @notice Makes the lockup stream non-cancelable.
    ///
    /// @dev Emits a {RenounceLockupStream} event.
    ///
    /// Notes:
    /// - This is an irreversible operation.
    /// - This function will attempt to call a hook on the recipient of the stream, if the recipient is a contract.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - `streamId` must point to an active lockup stream.
    /// - `msg.sender` must be the sender of the stream.
    /// - The lockup stream must be cancelable.
    ///
    /// @param streamId The id of the lockup stream to renounce.
    function renounce(uint256 streamId) external;

    /// @notice Sets a new NFT descriptor contract, which produces the URI describing the Sablier stream NFTs.
    ///
    /// @dev Emits a {SetNFTDescriptor} event.
    ///
    /// Notes:
    /// - Does not revert if the NFT descriptor is the same.
    ///
    /// Requirements:
    /// - `msg.sender` must be the contract admin.
    ///
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    function setNFTDescriptor(ISablierV2NFTDescriptor newNFTDescriptor) external;

    /// @notice Withdraws the provided amount of assets from the lockup stream to the provided address `to`.
    ///
    /// @dev Emits a {WithdrawFromLockupStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - This function will attempt to call a hook on the recipient of the stream, if the recipient is a contract.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - `streamId` must point to a lockup stream that is either active or canceled.
    /// - `msg.sender` must be the sender of the stream, the recipient of the stream (a.k.a the NFT owner) or an
    /// approved third party.
    /// - `to` must be the recipient if `msg.sender` is the sender of the stream.
    /// - `to` must not be the zero address.
    /// - `amount` must be greater than zero and must not exceed the withdrawable amount.
    ///
    /// @param streamId The id of the lockup stream to withdraw from.
    /// @param to The address that receives the withdrawn assets.
    /// @param amount The amount to withdraw, denoted in units of the asset's decimals.
    function withdraw(uint256 streamId, address to, uint128 amount) external;

    /// @notice Withdraws the maximum withdrawable amount from the lockup stream to the provided address `to`.
    ///
    /// @dev Emits a {WithdrawFromLockupStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - All from {withdraw}.
    ///
    /// Requirements:
    /// - All from {withdraw}.
    ///
    /// @param streamId The id of the lockup stream to withdraw from.
    /// @param to The address that receives the withdrawn assets.
    function withdrawMax(uint256 streamId, address to) external;

    /// @notice Withdraws assets from multiple lockup streams to the provided address `to`.
    ///
    /// @dev Emits multiple {WithdrawFromLockupStream} and {Transfer} events.
    ///
    /// Notes:
    /// - This function will attempt to call a hook on the recipient of each stream.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - `to` must not be the zero address.
    /// - There must be as many `streamIds` as `amounts`.
    /// - `msg.sender` must be either the recipient or an approved third party of each stream.
    /// - Each value in `streamId` must point to a lockup stream that is either active or canceled.
    /// - Each value in `amounts` must be greater than zero and must not exceed the corresponding maximum withdrawable
    /// amount.
    ///
    /// @param streamIds The ids of the lockup streams to withdraw from.
    /// @param to The address that receives the withdrawn assets.
    /// @param amounts The amounts to withdraw, denoted in units of the asset's decimals.
    function withdrawMultiple(uint256[] calldata streamIds, address to, uint128[] calldata amounts) external;
}
