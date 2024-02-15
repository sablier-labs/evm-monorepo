// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import { ISablierV2Comptroller } from "../interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Lockup } from "../interfaces/ISablierV2Lockup.sol";
import { ISablierV2NFTDescriptor } from "../interfaces/ISablierV2NFTDescriptor.sol";
import { ISablierV2Recipient } from "../interfaces/hooks/ISablierV2Recipient.sol";
import { ISablierV2Sender } from "../interfaces/hooks/ISablierV2Sender.sol";
import { Errors } from "../libraries/Errors.sol";
import { Lockup } from "../types/DataTypes.sol";
import { SablierV2Base } from "./SablierV2Base.sol";

/// @title SablierV2Lockup
/// @notice See the documentation in {ISablierV2Lockup}.
abstract contract SablierV2Lockup is
    IERC4906, // 2 inherited components
    SablierV2Base, // 4 inherited components
    ISablierV2Lockup, // 4 inherited components
    ERC721 // 6 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    uint256 public override nextStreamId;

    /// @inheritdoc ISablierV2Lockup
    ISablierV2NFTDescriptor public override nftDescriptor;

    /// @dev Sablier V2 Lockup streams mapped by unsigned integers.
    mapping(uint256 id => Lockup.Stream stream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialComptroller The address of the initial comptroller.
    /// @param initialNFTDescriptor The address of the initial NFT descriptor.
    constructor(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        ISablierV2NFTDescriptor initialNFTDescriptor
    )
        SablierV2Base(initialAdmin, initialComptroller)
    {
        nftDescriptor = initialNFTDescriptor;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `streamId` does not reference a null stream.
    modifier notNull(uint256 streamId) {
        if (!_streams[streamId].isStream) {
            revert Errors.SablierV2Lockup_Null(streamId);
        }
        _;
    }

    /// @dev Emits an ERC-4906 event to trigger an update of the NFT metadata.
    modifier updateMetadata(uint256 streamId) {
        _;
        emit MetadataUpdate({ _tokenId: streamId });
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    function getAsset(uint256 streamId) external view override notNull(streamId) returns (IERC20 asset) {
        asset = _streams[streamId].asset;
    }

    /// @inheritdoc ISablierV2Lockup
    function getDepositedAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 depositedAmount)
    {
        depositedAmount = _streams[streamId].amounts.deposited;
    }

    /// @inheritdoc ISablierV2Lockup
    function getEndTime(uint256 streamId) external view override notNull(streamId) returns (uint40 endTime) {
        endTime = _streams[streamId].endTime;
    }

    /// @inheritdoc ISablierV2Lockup
    function getRecipient(uint256 streamId) external view override returns (address recipient) {
        // Checks: the stream NFT exists and return the owner, which is the stream's recipient.
        recipient = _requireOwned({ tokenId: streamId });
    }

    /// @inheritdoc ISablierV2Lockup
    function getRefundedAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 refundedAmount)
    {
        refundedAmount = _streams[streamId].amounts.refunded;
    }

    /// @inheritdoc ISablierV2Lockup
    function getSender(uint256 streamId) external view override notNull(streamId) returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2Lockup
    function getStartTime(uint256 streamId) external view override notNull(streamId) returns (uint40 startTime) {
        startTime = _streams[streamId].startTime;
    }

    /// @inheritdoc ISablierV2Lockup
    function getWithdrawnAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 withdrawnAmount)
    {
        withdrawnAmount = _streams[streamId].amounts.withdrawn;
    }

    /// @inheritdoc ISablierV2Lockup
    function isCancelable(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        if (_statusOf(streamId) != Lockup.Status.SETTLED) {
            result = _streams[streamId].isCancelable;
        }
    }

    /// @inheritdoc ISablierV2Lockup
    function isCold(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        Lockup.Status status = _statusOf(streamId);
        result = status == Lockup.Status.SETTLED || status == Lockup.Status.CANCELED || status == Lockup.Status.DEPLETED;
    }

    /// @inheritdoc ISablierV2Lockup
    function isDepleted(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].isDepleted;
    }

    /// @inheritdoc ISablierV2Lockup
    function isStream(uint256 streamId) external view override returns (bool result) {
        result = _streams[streamId].isStream;
    }

    /// @inheritdoc ISablierV2Lockup
    function isTransferable(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].isTransferable;
    }

    /// @inheritdoc ISablierV2Lockup
    function isWarm(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        Lockup.Status status = _statusOf(streamId);
        result = status == Lockup.Status.PENDING || status == Lockup.Status.STREAMING;
    }

    /// @inheritdoc ISablierV2Lockup
    function refundableAmountOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 refundableAmount)
    {
        // These checks are needed because {_calculateStreamedAmount} does not look up the stream's status. Note that
        // checking for `isCancelable` also checks if the stream `wasCanceled` thanks to the protocol invariant that
        // canceled streams are not cancelable anymore.
        if (_streams[streamId].isCancelable && !_streams[streamId].isDepleted) {
            refundableAmount = _streams[streamId].amounts.deposited - _calculateStreamedAmount(streamId);
        }
        // Otherwise, the result is implicitly zero.
    }

    /// @inheritdoc ISablierV2Lockup
    function statusOf(uint256 streamId) external view override notNull(streamId) returns (Lockup.Status status) {
        status = _statusOf(streamId);
    }

    /// @inheritdoc ISablierV2Lockup
    function streamedAmountOf(uint256 streamId)
        public
        view
        virtual
        override
        notNull(streamId)
        returns (uint128 streamedAmount)
    {
        streamedAmount = _streamedAmountOf(streamId);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 streamId) public view override(IERC721Metadata, ERC721) returns (string memory uri) {
        // Checks: the stream NFT exists.
        _requireOwned({ tokenId: streamId });

        // Generate the URI describing the stream NFT.
        uri = nftDescriptor.tokenURI({ sablier: this, streamId: streamId });
    }

    /// @inheritdoc ISablierV2Lockup
    function wasCanceled(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].wasCanceled;
    }

    /// @inheritdoc ISablierV2Lockup
    function withdrawableAmountOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 withdrawableAmount)
    {
        withdrawableAmount = _withdrawableAmountOf(streamId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    function burn(uint256 streamId) external override noDelegateCall notNull(streamId) {
        // Checks: only depleted streams can be burned.
        if (!_streams[streamId].isDepleted) {
            revert Errors.SablierV2Lockup_StreamNotDepleted(streamId);
        }

        // Checks:
        // 1. NFT exists (see {IERC721.getApproved}).
        // 2. `msg.sender` is either the owner of the NFT or an approved third party.
        if (!_isCallerStreamRecipientOrApproved(streamId)) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }

        // Effects: burn the NFT.
        _burn({ tokenId: streamId });
    }

    /// @inheritdoc ISablierV2Lockup
    function cancel(uint256 streamId) public override noDelegateCall notNull(streamId) {
        // Checks: the stream is neither depleted nor canceled.
        if (_streams[streamId].isDepleted) {
            revert Errors.SablierV2Lockup_StreamDepleted(streamId);
        } else if (_streams[streamId].wasCanceled) {
            revert Errors.SablierV2Lockup_StreamCanceled(streamId);
        }

        // Checks: `msg.sender` is the stream's sender.
        if (!_isCallerStreamSender(streamId)) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }

        // Checks, Effects and Interactions: cancel the stream.
        _cancel(streamId);
    }

    /// @inheritdoc ISablierV2Lockup
    function cancelMultiple(uint256[] calldata streamIds) external override noDelegateCall {
        // Iterate over the provided array of stream ids and cancel each stream.
        uint256 count = streamIds.length;
        for (uint256 i = 0; i < count; ++i) {
            // Effects and Interactions: cancel the stream.
            cancel(streamIds[i]);
        }
    }

    /// @inheritdoc ISablierV2Lockup
    function renounce(uint256 streamId) external override noDelegateCall notNull(streamId) updateMetadata(streamId) {
        // Checks: the stream is not cold.
        Lockup.Status status = _statusOf(streamId);
        if (status == Lockup.Status.DEPLETED) {
            revert Errors.SablierV2Lockup_StreamDepleted(streamId);
        } else if (status == Lockup.Status.CANCELED) {
            revert Errors.SablierV2Lockup_StreamCanceled(streamId);
        } else if (status == Lockup.Status.SETTLED) {
            revert Errors.SablierV2Lockup_StreamSettled(streamId);
        }

        // Checks: `msg.sender` is the stream's sender.
        if (!_isCallerStreamSender(streamId)) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }

        // Checks and Effects: renounce the stream.
        _renounce(streamId);

        // Log the renouncement.
        emit ISablierV2Lockup.RenounceLockupStream(streamId);

        // Interactions: if the recipient is a contract, try to invoke the renounce hook on the recipient without
        // reverting if the hook is not implemented, and also without bubbling up any potential revert.
        address recipient = _ownerOf(streamId);
        if (recipient.code.length > 0) {
            try ISablierV2Recipient(recipient).onLockupStreamRenounced(streamId) { } catch { }
        }
    }

    /// @inheritdoc ISablierV2Lockup
    function setNFTDescriptor(ISablierV2NFTDescriptor newNFTDescriptor) external override onlyAdmin {
        // Effects: set the NFT descriptor.
        ISablierV2NFTDescriptor oldNftDescriptor = nftDescriptor;
        nftDescriptor = newNFTDescriptor;

        // Log the change of the NFT descriptor.
        emit ISablierV2Lockup.SetNFTDescriptor({
            admin: msg.sender,
            oldNFTDescriptor: oldNftDescriptor,
            newNFTDescriptor: newNFTDescriptor
        });

        // Refresh the NFT metadata for all streams.
        emit BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: nextStreamId - 1 });
    }

    /// @inheritdoc ISablierV2Lockup
    function withdraw(
        uint256 streamId,
        address to,
        uint128 amount
    )
        public
        override
        noDelegateCall
        notNull(streamId)
        updateMetadata(streamId)
    {
        // Checks: the stream is not depleted.
        if (_streams[streamId].isDepleted) {
            revert Errors.SablierV2Lockup_StreamDepleted(streamId);
        }

        // Checks: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierV2Lockup_WithdrawToZeroAddress();
        }

        // Checks: the withdraw amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2Lockup_WithdrawAmountZero(streamId);
        }

        // Retrieve the recipient from storage.
        address recipient = _ownerOf(streamId);

        // Checks: if `msg.sender` is neither the stream's recipient nor an approved third party, the withdrawal address
        // must be the recipient.
        if (to != recipient && !_isCallerStreamRecipientOrApproved(streamId)) {
            revert Errors.SablierV2Lockup_WithdrawalAddressNotRecipient(streamId, msg.sender, to);
        }

        // Checks: the withdraw amount is not greater than the withdrawable amount.
        uint128 withdrawableAmount = _withdrawableAmountOf(streamId);
        if (amount > withdrawableAmount) {
            revert Errors.SablierV2Lockup_Overdraw(streamId, amount, withdrawableAmount);
        }

        // Retrieve the sender from storage.
        address sender = _streams[streamId].sender;

        // Effects and Interactions: make the withdrawal.
        _withdraw(streamId, to, amount);

        // Interactions: if `msg.sender` is not the recipient and the recipient is a contract, try to invoke the
        // withdraw hook on it without reverting if the hook is not implemented, and also without bubbling up
        // any potential revert.
        if (msg.sender != recipient && recipient.code.length > 0) {
            try ISablierV2Recipient(recipient).onLockupStreamWithdrawn({
                streamId: streamId,
                caller: msg.sender,
                to: to,
                amount: amount
            }) { } catch { }
        }

        // Interactions: if `msg.sender` is not the sender and the sender is a contract, try to invoke the
        // withdraw hook on it without reverting if the hook is not implemented, and also without bubbling up
        // any potential revert.
        if (msg.sender != sender && sender.code.length > 0) {
            try ISablierV2Sender(sender).onLockupStreamWithdrawn({
                streamId: streamId,
                caller: msg.sender,
                to: to,
                amount: amount
            }) { } catch { }
        }
    }

    /// @inheritdoc ISablierV2Lockup
    function withdrawMax(uint256 streamId, address to) external override {
        withdraw({ streamId: streamId, to: to, amount: _withdrawableAmountOf(streamId) });
    }

    /// @inheritdoc ISablierV2Lockup
    function withdrawMaxAndTransfer(
        uint256 streamId,
        address newRecipient
    )
        external
        override
        noDelegateCall
        notNull(streamId)
    {
        // Checks: the caller is the current recipient. This also checks that the NFT was not burned.
        address currentRecipient = _ownerOf(streamId);
        if (msg.sender != currentRecipient) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }

        // Skip the withdrawal if the withdrawable amount is zero.
        uint128 withdrawableAmount = _withdrawableAmountOf(streamId);
        if (withdrawableAmount > 0) {
            withdraw({ streamId: streamId, to: currentRecipient, amount: withdrawableAmount });
        }

        // Checks and Effects: transfer the NFT.
        _transfer({ from: currentRecipient, to: newRecipient, tokenId: streamId });
    }

    /// @inheritdoc ISablierV2Lockup
    function withdrawMultiple(
        uint256[] calldata streamIds,
        uint128[] calldata amounts
    )
        external
        override
        noDelegateCall
    {
        // Checks: there is an equal number of `streamIds` and `amounts`.
        uint256 streamIdsCount = streamIds.length;
        uint256 amountsCount = amounts.length;
        if (streamIdsCount != amountsCount) {
            revert Errors.SablierV2Lockup_WithdrawArrayCountsNotEqual(streamIdsCount, amountsCount);
        }

        // Iterate over the provided array of stream ids and withdraw from each stream.
        for (uint256 i = 0; i < streamIdsCount; ++i) {
            // Checks, Effects and Interactions: check the parameters and make the withdrawal.
            withdraw({ streamId: streamIds[i], to: _ownerOf(streamIds[i]), amount: amounts[i] });
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Calculates the streamed amount of the stream without looking up the stream's status, which is
    /// implemented by child contracts, it can vary depending on the model.
    function _calculateStreamedAmount(uint256 streamId) internal view virtual returns (uint128);

    /// @notice Checks whether `msg.sender` is the stream's recipient or an approved third party.
    /// @param streamId The stream id for the query.
    function _isCallerStreamRecipientOrApproved(uint256 streamId) internal view returns (bool) {
        address recipient = _ownerOf(streamId);
        return msg.sender == recipient || isApprovedForAll({ owner: recipient, operator: msg.sender })
            || getApproved(streamId) == msg.sender;
    }

    /// @notice Checks whether `msg.sender` is the stream's sender.
    /// @param streamId The stream id for the query.
    function _isCallerStreamSender(uint256 streamId) internal view returns (bool) {
        return msg.sender == _streams[streamId].sender;
    }

    /// @dev Retrieves the stream's status without performing a null check.
    function _statusOf(uint256 streamId) internal view returns (Lockup.Status) {
        if (_streams[streamId].isDepleted) {
            return Lockup.Status.DEPLETED;
        } else if (_streams[streamId].wasCanceled) {
            return Lockup.Status.CANCELED;
        }

        if (block.timestamp < _streams[streamId].startTime) {
            return Lockup.Status.PENDING;
        }

        if (_calculateStreamedAmount(streamId) < _streams[streamId].amounts.deposited) {
            return Lockup.Status.STREAMING;
        } else {
            return Lockup.Status.SETTLED;
        }
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _streamedAmountOf(uint256 streamId) internal view returns (uint128) {
        Lockup.Amounts memory amounts = _streams[streamId].amounts;

        if (_streams[streamId].isDepleted) {
            return amounts.withdrawn;
        } else if (_streams[streamId].wasCanceled) {
            return amounts.deposited - amounts.refunded;
        }

        return _calculateStreamedAmount(streamId);
    }

    /// @notice Overrides the internal ERC-721 `_update` function to check that the stream is transferable and emit
    /// an ERC-4906 event.
    /// @dev There are two cases when the transferable flag is ignored:
    /// - If `from` is 0, then the update is a mint and is allowed.
    /// - If `to` is 0, then the update is a burn and is also allowed.
    /// @param to The address of the new recipient of the stream.
    /// @param streamId Id of the stream to update.
    /// @param auth Optional parameter. If the value is non 0, the upstream implementation of this function will check
    /// that `auth` is either the recipient of the stream, or an approved third party.
    /// @return The original recipient of the `streamId` before the update.
    function _update(
        address to,
        uint256 streamId,
        address auth
    )
        internal
        override
        updateMetadata(streamId)
        returns (address)
    {
        address from = _ownerOf(streamId);

        if (!_streams[streamId].isTransferable && from != address(0) && to != address(0)) {
            revert Errors.SablierV2Lockup_NotTransferable(streamId);
        }

        return super._update(to, streamId, auth);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _withdrawableAmountOf(uint256 streamId) internal view returns (uint128) {
        return _streamedAmountOf(streamId) - _streams[streamId].amounts.withdrawn;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _cancel(uint256 streamId) internal {
        // Calculate the streamed amount.
        uint128 streamedAmount = _calculateStreamedAmount(streamId);

        // Retrieve the amounts from storage.
        Lockup.Amounts memory amounts = _streams[streamId].amounts;

        // Checks: the stream is not settled.
        if (streamedAmount >= amounts.deposited) {
            revert Errors.SablierV2Lockup_StreamSettled(streamId);
        }

        // Checks: the stream is cancelable.
        if (!_streams[streamId].isCancelable) {
            revert Errors.SablierV2Lockup_StreamNotCancelable(streamId);
        }

        // Calculate the sender's and the recipient's amount.
        uint128 senderAmount = amounts.deposited - streamedAmount;
        uint128 recipientAmount = streamedAmount - amounts.withdrawn;

        // Effects: mark the stream as canceled.
        _streams[streamId].wasCanceled = true;

        // Effects: make the stream not cancelable anymore, because a stream can only be canceled once.
        _streams[streamId].isCancelable = false;

        // Effects: If there are no assets left for the recipient to withdraw, mark the stream as depleted.
        if (recipientAmount == 0) {
            _streams[streamId].isDepleted = true;
        }

        // Effects: set the refunded amount.
        _streams[streamId].amounts.refunded = senderAmount;

        // Retrieve the sender and the recipient from storage.
        address sender = _streams[streamId].sender;
        address recipient = _ownerOf(streamId);

        // Retrieve the ERC-20 asset from storage.
        IERC20 asset = _streams[streamId].asset;

        // Interactions: refund the sender.
        asset.safeTransfer({ to: sender, value: senderAmount });

        // Log the cancellation.
        emit ISablierV2Lockup.CancelLockupStream(streamId, sender, recipient, asset, senderAmount, recipientAmount);

        // Emits an ERC-4906 event to trigger an update of the NFT metadata.
        emit MetadataUpdate({ _tokenId: streamId });

        // Interactions: if the recipient is a contract, try to invoke the cancel hook on the recipient without
        // reverting if the hook is not implemented, and without bubbling up any potential revert.
        if (recipient.code.length > 0) {
            try ISablierV2Recipient(recipient).onLockupStreamCanceled({
                streamId: streamId,
                sender: sender,
                senderAmount: senderAmount,
                recipientAmount: recipientAmount
            }) { } catch { }
        }
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _renounce(uint256 streamId) internal {
        // Checks: the stream is cancelable.
        if (!_streams[streamId].isCancelable) {
            revert Errors.SablierV2Lockup_StreamNotCancelable(streamId);
        }

        // Effects: renounce the stream by making it not cancelable.
        _streams[streamId].isCancelable = false;
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal {
        // Effects: update the withdrawn amount.
        _streams[streamId].amounts.withdrawn = _streams[streamId].amounts.withdrawn + amount;

        // Retrieve the amounts from storage.
        Lockup.Amounts memory amounts = _streams[streamId].amounts;

        // Using ">=" instead of "==" for additional safety reasons. In the event of an unforeseen increase in the
        // withdrawn amount, the stream will still be marked as depleted.
        if (amounts.withdrawn >= amounts.deposited - amounts.refunded) {
            // Effects: mark the stream as depleted.
            _streams[streamId].isDepleted = true;

            // Effects: make the stream not cancelable anymore, because a depleted stream cannot be canceled.
            _streams[streamId].isCancelable = false;
        }

        // Retrieve the ERC-20 asset from storage.
        IERC20 asset = _streams[streamId].asset;

        // Interactions: perform the ERC-20 transfer.
        asset.safeTransfer({ to: to, value: amount });

        // Log the withdrawal.
        emit ISablierV2Lockup.WithdrawFromLockupStream(streamId, to, asset, amount);
    }
}
