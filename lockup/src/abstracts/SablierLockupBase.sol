// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ILockupNFTDescriptor } from "./../interfaces/ILockupNFTDescriptor.sol";
import { ISablierLockupBase } from "./../interfaces/ISablierLockupBase.sol";
import { ISablierLockupRecipient } from "./../interfaces/ISablierLockupRecipient.sol";
import { Errors } from "./../libraries/Errors.sol";
import { Lockup } from "./../types/DataTypes.sol";
import { Adminable } from "./Adminable.sol";
import { Batch } from "./Batch.sol";
import { NoDelegateCall } from "./NoDelegateCall.sol";

/// @title SablierLockupBase
/// @notice See the documentation in {ISablierLockupBase}.
abstract contract SablierLockupBase is
    Batch, // 1 inherited components
    NoDelegateCall, // 0 inherited components
    Adminable, // 1 inherited components
    ISablierLockupBase, // 6 inherited components
    ERC721 // 6 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockupBase
    UD60x18 public constant override MAX_BROKER_FEE = UD60x18.wrap(0.1e18);

    /// @inheritdoc ISablierLockupBase
    uint256 public override nextStreamId;

    /// @inheritdoc ISablierLockupBase
    ILockupNFTDescriptor public override nftDescriptor;

    /// @dev Mapping of contracts allowed to hook to Sablier when a stream is canceled or when tokens are withdrawn.
    mapping(address recipient => bool allowed) internal _allowedToHook;

    /// @dev Lockup streams mapped by unsigned integers.
    mapping(uint256 id => Lockup.Stream stream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialNFTDescriptor The address of the initial NFT descriptor.
    constructor(address initialAdmin, ILockupNFTDescriptor initialNFTDescriptor) Adminable(initialAdmin) {
        nftDescriptor = initialNFTDescriptor;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `streamId` does not reference a null stream.
    modifier notNull(uint256 streamId) {
        if (!_streams[streamId].isStream) {
            revert Errors.SablierLockupBase_Null(streamId);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockupBase
    function getDepositedAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 depositedAmount)
    {
        depositedAmount = _streams[streamId].amounts.deposited;
    }

    /// @inheritdoc ISablierLockupBase
    function getEndTime(uint256 streamId) external view override notNull(streamId) returns (uint40 endTime) {
        endTime = _streams[streamId].endTime;
    }

    /// @inheritdoc ISablierLockupBase
    function getLockupModel(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (Lockup.Model lockupModel)
    {
        lockupModel = _streams[streamId].lockupModel;
    }

    /// @inheritdoc ISablierLockupBase
    function getRecipient(uint256 streamId) external view override returns (address recipient) {
        // Check the stream NFT exists and return the owner, which is the stream's recipient.
        recipient = _requireOwned({ tokenId: streamId });
    }

    /// @inheritdoc ISablierLockupBase
    function getRefundedAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 refundedAmount)
    {
        refundedAmount = _streams[streamId].amounts.refunded;
    }

    /// @inheritdoc ISablierLockupBase
    function getSender(uint256 streamId) external view override notNull(streamId) returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierLockupBase
    function getStartTime(uint256 streamId) external view override notNull(streamId) returns (uint40 startTime) {
        startTime = _streams[streamId].startTime;
    }

    /// @inheritdoc ISablierLockupBase
    function getUnderlyingToken(uint256 streamId) external view override notNull(streamId) returns (IERC20 token) {
        token = _streams[streamId].token;
    }

    /// @inheritdoc ISablierLockupBase
    function getWithdrawnAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 withdrawnAmount)
    {
        withdrawnAmount = _streams[streamId].amounts.withdrawn;
    }

    /// @inheritdoc ISablierLockupBase
    function isAllowedToHook(address recipient) external view returns (bool result) {
        result = _allowedToHook[recipient];
    }

    /// @inheritdoc ISablierLockupBase
    function isCancelable(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        if (_statusOf(streamId) != Lockup.Status.SETTLED) {
            result = _streams[streamId].isCancelable;
        }
    }

    /// @inheritdoc ISablierLockupBase
    function isCold(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        Lockup.Status status = _statusOf(streamId);
        result = status == Lockup.Status.SETTLED || status == Lockup.Status.CANCELED || status == Lockup.Status.DEPLETED;
    }

    /// @inheritdoc ISablierLockupBase
    function isDepleted(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].isDepleted;
    }

    /// @inheritdoc ISablierLockupBase
    function isStream(uint256 streamId) external view override returns (bool result) {
        result = _streams[streamId].isStream;
    }

    /// @inheritdoc ISablierLockupBase
    function isTransferable(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].isTransferable;
    }

    /// @inheritdoc ISablierLockupBase
    function isWarm(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        Lockup.Status status = _statusOf(streamId);
        result = status == Lockup.Status.PENDING || status == Lockup.Status.STREAMING;
    }

    /// @inheritdoc ISablierLockupBase
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

    /// @inheritdoc ISablierLockupBase
    function statusOf(uint256 streamId) external view override notNull(streamId) returns (Lockup.Status status) {
        status = _statusOf(streamId);
    }

    /// @inheritdoc ISablierLockupBase
    function streamedAmountOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 streamedAmount)
    {
        streamedAmount = _streamedAmountOf(streamId);
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC721) returns (bool) {
        // 0x49064906 is the ERC-165 interface ID required by ERC-4906
        return interfaceId == 0x49064906 || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 streamId) public view override(IERC721Metadata, ERC721) returns (string memory uri) {
        // Check: the stream NFT exists.
        _requireOwned({ tokenId: streamId });

        // Generate the URI describing the stream NFT.
        uri = nftDescriptor.tokenURI({ sablier: this, streamId: streamId });
    }

    /// @inheritdoc ISablierLockupBase
    function wasCanceled(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].wasCanceled;
    }

    /// @inheritdoc ISablierLockupBase
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

    /// @inheritdoc ISablierLockupBase
    function allowToHook(address recipient) external override onlyAdmin {
        // Check: non-zero code size.
        if (recipient.code.length == 0) {
            revert Errors.SablierLockupBase_AllowToHookZeroCodeSize(recipient);
        }

        // Check: recipients implements the ERC-165 interface ID required by {ISablierLockupRecipient}.
        bytes4 interfaceId = type(ISablierLockupRecipient).interfaceId;
        if (!ISablierLockupRecipient(recipient).supportsInterface(interfaceId)) {
            revert Errors.SablierLockupBase_AllowToHookUnsupportedInterface(recipient);
        }

        // Effect: put the recipient on the allowlist.
        _allowedToHook[recipient] = true;

        // Log the allowlist addition.
        emit ISablierLockupBase.AllowToHook({ admin: msg.sender, recipient: recipient });
    }

    /// @inheritdoc ISablierLockupBase
    function burn(uint256 streamId) external payable override noDelegateCall notNull(streamId) {
        // Check: only depleted streams can be burned.
        if (!_streams[streamId].isDepleted) {
            revert Errors.SablierLockupBase_StreamNotDepleted(streamId);
        }

        // Retrieve the current owner.
        address currentRecipient = _ownerOf(streamId);

        // Check:
        // 1. NFT exists (see {IERC721.getApproved}).
        // 2. `msg.sender` is either the owner of the NFT or an approved third party.
        if (!_isCallerStreamRecipientOrApproved(streamId, currentRecipient)) {
            revert Errors.SablierLockupBase_Unauthorized(streamId, msg.sender);
        }

        // Effect: burn the NFT.
        _burn({ tokenId: streamId });
    }

    /// @inheritdoc ISablierLockupBase
    function cancel(uint256 streamId) public payable override noDelegateCall notNull(streamId) {
        // Check: the stream is neither depleted nor canceled.
        if (_streams[streamId].isDepleted) {
            revert Errors.SablierLockupBase_StreamDepleted(streamId);
        } else if (_streams[streamId].wasCanceled) {
            revert Errors.SablierLockupBase_StreamCanceled(streamId);
        }

        // Check: `msg.sender` is the stream's sender.
        if (!_isCallerStreamSender(streamId)) {
            revert Errors.SablierLockupBase_Unauthorized(streamId, msg.sender);
        }

        // Checks, Effects and Interactions: cancel the stream.
        _cancel(streamId);
    }

    /// @inheritdoc ISablierLockupBase
    function cancelMultiple(uint256[] calldata streamIds) external payable override noDelegateCall {
        // Iterate over the provided array of stream IDs and cancel each stream.
        uint256 count = streamIds.length;
        for (uint256 i = 0; i < count; ++i) {
            // Effects and Interactions: cancel the stream.
            cancel(streamIds[i]);
        }
    }

    /// @inheritdoc ISablierLockupBase
    function collectFees() external override {
        uint256 feeAmount = address(this).balance;

        // Effect: transfer the fees to the admin.
        (bool success,) = admin.call{ value: feeAmount }("");

        // Revert if the call failed.
        if (!success) {
            revert Errors.SablierLockupBase_FeeTransferFail(admin, feeAmount);
        }

        // Log the fee withdrawal.
        emit ISablierLockupBase.CollectFees({ admin: admin, feeAmount: feeAmount });
    }

    /// @inheritdoc ISablierLockupBase
    function renounce(uint256 streamId) public payable override noDelegateCall notNull(streamId) {
        // Check: the stream is not cold.
        Lockup.Status status = _statusOf(streamId);
        if (status == Lockup.Status.DEPLETED) {
            revert Errors.SablierLockupBase_StreamDepleted(streamId);
        } else if (status == Lockup.Status.CANCELED) {
            revert Errors.SablierLockupBase_StreamCanceled(streamId);
        } else if (status == Lockup.Status.SETTLED) {
            revert Errors.SablierLockupBase_StreamSettled(streamId);
        }

        // Check: `msg.sender` is the stream's sender.
        if (!_isCallerStreamSender(streamId)) {
            revert Errors.SablierLockupBase_Unauthorized(streamId, msg.sender);
        }

        // Checks and Effects: renounce the stream.
        _renounce(streamId);

        // Log the renouncement.
        emit ISablierLockupBase.RenounceLockupStream(streamId);
    }

    /// @inheritdoc ISablierLockupBase
    function renounceMultiple(uint256[] calldata streamIds) external payable override noDelegateCall {
        // Iterate over the provided array of stream IDs and renounce each stream.
        uint256 count = streamIds.length;
        for (uint256 i = 0; i < count; ++i) {
            // Call the existing renounce function for each stream ID.
            renounce(streamIds[i]);
        }
    }

    /// @inheritdoc ISablierLockupBase
    function setNFTDescriptor(ILockupNFTDescriptor newNFTDescriptor) external override onlyAdmin {
        // Effect: set the NFT descriptor.
        ILockupNFTDescriptor oldNftDescriptor = nftDescriptor;
        nftDescriptor = newNFTDescriptor;

        // Log the change of the NFT descriptor.
        emit ISablierLockupBase.SetNFTDescriptor({
            admin: msg.sender,
            oldNFTDescriptor: oldNftDescriptor,
            newNFTDescriptor: newNFTDescriptor
        });

        // Refresh the NFT metadata for all streams.
        emit BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: nextStreamId - 1 });
    }

    /// @inheritdoc ISablierLockupBase
    function withdraw(
        uint256 streamId,
        address to,
        uint128 amount
    )
        public
        payable
        override
        noDelegateCall
        notNull(streamId)
    {
        // Check: the stream is not depleted.
        if (_streams[streamId].isDepleted) {
            revert Errors.SablierLockupBase_StreamDepleted(streamId);
        }

        // Check: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierLockupBase_WithdrawToZeroAddress(streamId);
        }

        // Retrieve the recipient from storage.
        address recipient = _ownerOf(streamId);

        // Check: `msg.sender` is neither the stream's recipient nor an approved third party, the withdrawal address
        // must be the recipient.
        if (to != recipient && !_isCallerStreamRecipientOrApproved(streamId, recipient)) {
            revert Errors.SablierLockupBase_WithdrawalAddressNotRecipient(streamId, msg.sender, to);
        }

        // Check: the withdraw amount is not zero.
        if (amount == 0) {
            revert Errors.SablierLockupBase_WithdrawAmountZero(streamId);
        }

        // Check: the withdraw amount is not greater than the withdrawable amount.
        uint128 withdrawableAmount = _withdrawableAmountOf(streamId);
        if (amount > withdrawableAmount) {
            revert Errors.SablierLockupBase_Overdraw(streamId, amount, withdrawableAmount);
        }

        // Effects and Interactions: make the withdrawal.
        _withdraw(streamId, to, amount);

        // Emit an ERC-4906 event to trigger an update of the NFT metadata.
        emit MetadataUpdate({ _tokenId: streamId });

        // Interaction: if `msg.sender` is not the recipient and the recipient is on the allowlist, run the hook.
        if (msg.sender != recipient && _allowedToHook[recipient]) {
            bytes4 selector = ISablierLockupRecipient(recipient).onSablierLockupWithdraw({
                streamId: streamId,
                caller: msg.sender,
                to: to,
                amount: amount
            });

            // Check: the recipient's hook returned the correct selector.
            if (selector != ISablierLockupRecipient.onSablierLockupWithdraw.selector) {
                revert Errors.SablierLockupBase_InvalidHookSelector(recipient);
            }
        }
    }

    /// @inheritdoc ISablierLockupBase
    function withdrawMax(uint256 streamId, address to) external payable override returns (uint128 withdrawnAmount) {
        withdrawnAmount = _withdrawableAmountOf(streamId);
        withdraw({ streamId: streamId, to: to, amount: withdrawnAmount });
    }

    /// @inheritdoc ISablierLockupBase
    function withdrawMaxAndTransfer(
        uint256 streamId,
        address newRecipient
    )
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        returns (uint128 withdrawnAmount)
    {
        // Retrieve the current owner. This also checks that the NFT was not burned.
        address currentRecipient = _ownerOf(streamId);

        // Check: `msg.sender` is neither the stream's recipient nor an approved third party.
        if (!_isCallerStreamRecipientOrApproved(streamId, currentRecipient)) {
            revert Errors.SablierLockupBase_Unauthorized(streamId, msg.sender);
        }

        // Skip the withdrawal if the withdrawable amount is zero.
        withdrawnAmount = _withdrawableAmountOf(streamId);
        if (withdrawnAmount > 0) {
            withdraw({ streamId: streamId, to: currentRecipient, amount: withdrawnAmount });
        }

        // Checks and Effects: transfer the NFT.
        _transfer({ from: currentRecipient, to: newRecipient, tokenId: streamId });
    }

    /// @inheritdoc ISablierLockupBase
    function withdrawMultiple(
        uint256[] calldata streamIds,
        uint128[] calldata amounts
    )
        external
        payable
        override
        noDelegateCall
    {
        // Check: there is an equal number of `streamIds` and `amounts`.
        uint256 streamIdsCount = streamIds.length;
        uint256 amountsCount = amounts.length;
        if (streamIdsCount != amountsCount) {
            revert Errors.SablierLockupBase_WithdrawArrayCountsNotEqual(streamIdsCount, amountsCount);
        }

        // Iterate over the provided array of stream IDs and withdraw from each stream to the recipient.
        for (uint256 i = 0; i < streamIdsCount; ++i) {
            // Checks, Effects and Interactions: withdraw using delegatecall.
            (bool success, bytes memory result) = address(this).delegatecall(
                abi.encodeCall(ISablierLockupBase.withdraw, (streamIds[i], _ownerOf(streamIds[i]), amounts[i]))
            );
            // If the withdrawal reverts, log it using an event, and continue with the next stream.
            if (!success) {
                emit InvalidWithdrawalInWithdrawMultiple(streamIds[i], result);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Calculates the streamed amount of the stream without looking up the stream's status.
    /// @dev This function is implemented by child contracts, so the logic varies depending on the model.
    function _calculateStreamedAmount(uint256 streamId) internal view virtual returns (uint128);

    /// @notice Checks whether `msg.sender` is the stream's recipient or an approved third party, when the
    /// `recipient` is known in advance.
    /// @param streamId The stream ID for the query.
    /// @param recipient The address of the stream's recipient.
    function _isCallerStreamRecipientOrApproved(uint256 streamId, address recipient) internal view returns (bool) {
        return msg.sender == recipient || isApprovedForAll({ owner: recipient, operator: msg.sender })
            || getApproved(streamId) == msg.sender;
    }

    /// @notice Checks whether `msg.sender` is the stream's sender.
    /// @param streamId The stream ID for the query.
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

        // Check: the stream is not settled.
        if (streamedAmount >= amounts.deposited) {
            revert Errors.SablierLockupBase_StreamSettled(streamId);
        }

        // Check: the stream is cancelable.
        if (!_streams[streamId].isCancelable) {
            revert Errors.SablierLockupBase_StreamNotCancelable(streamId);
        }

        // Calculate the sender's amount.
        uint128 senderAmount;
        unchecked {
            senderAmount = amounts.deposited - streamedAmount;
        }

        // Calculate the recipient's amount.
        uint128 recipientAmount = streamedAmount - amounts.withdrawn;

        // Effect: mark the stream as canceled.
        _streams[streamId].wasCanceled = true;

        // Effect: make the stream not cancelable anymore, because a stream can only be canceled once.
        _streams[streamId].isCancelable = false;

        // Effect: if there are no tokens left for the recipient to withdraw, mark the stream as depleted.
        if (recipientAmount == 0) {
            _streams[streamId].isDepleted = true;
        }

        // Effect: set the refunded amount.
        _streams[streamId].amounts.refunded = senderAmount;

        // Retrieve the sender and the recipient from storage.
        address sender = _streams[streamId].sender;
        address recipient = _ownerOf(streamId);

        // Retrieve the ERC-20 token from storage.
        IERC20 token = _streams[streamId].token;

        // Interaction: refund the sender.
        token.safeTransfer({ to: sender, value: senderAmount });

        // Log the cancellation.
        emit ISablierLockupBase.CancelLockupStream(streamId, sender, recipient, token, senderAmount, recipientAmount);

        // Emit an ERC-4906 event to trigger an update of the NFT metadata.
        emit MetadataUpdate({ _tokenId: streamId });

        // Interaction: if the recipient is on the allowlist, run the hook.
        if (_allowedToHook[recipient]) {
            bytes4 selector = ISablierLockupRecipient(recipient).onSablierLockupCancel({
                streamId: streamId,
                sender: sender,
                senderAmount: senderAmount,
                recipientAmount: recipientAmount
            });

            // Check: the recipient's hook returned the correct selector.
            if (selector != ISablierLockupRecipient.onSablierLockupCancel.selector) {
                revert Errors.SablierLockupBase_InvalidHookSelector(recipient);
            }
        }
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _renounce(uint256 streamId) internal {
        // Check: the stream is cancelable.
        if (!_streams[streamId].isCancelable) {
            revert Errors.SablierLockupBase_StreamNotCancelable(streamId);
        }

        // Effect: renounce the stream by making it not cancelable.
        _streams[streamId].isCancelable = false;
    }

    /// @notice Overrides the {ERC-721._update} function to check that the stream is transferable, and emits an
    /// ERC-4906 event.
    /// @dev There are two cases when the transferable flag is ignored:
    /// - If the current owner is 0, then the update is a mint and is allowed.
    /// - If `to` is 0, then the update is a burn and is also allowed.
    /// @param to The address of the new recipient of the stream.
    /// @param streamId ID of the stream to update.
    /// @param auth Optional parameter. If the value is not zero, the overridden implementation will check that
    /// `auth` is either the recipient of the stream, or an approved third party.
    /// @return The original recipient of the `streamId` before the update.
    function _update(address to, uint256 streamId, address auth) internal override returns (address) {
        address from = _ownerOf(streamId);

        if (from != address(0) && to != address(0) && !_streams[streamId].isTransferable) {
            revert Errors.SablierLockupBase_NotTransferable(streamId);
        }

        // Emit an ERC-4906 event to trigger an update of the NFT metadata.
        emit MetadataUpdate({ _tokenId: streamId });

        return super._update(to, streamId, auth);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal {
        // Effect: update the withdrawn amount.
        _streams[streamId].amounts.withdrawn = _streams[streamId].amounts.withdrawn + amount;

        // Retrieve the amounts from storage.
        Lockup.Amounts memory amounts = _streams[streamId].amounts;

        // Using ">=" instead of "==" for additional safety reasons. In the event of an unforeseen increase in the
        // withdrawn amount, the stream will still be marked as depleted.
        if (amounts.withdrawn >= amounts.deposited - amounts.refunded) {
            // Effect: mark the stream as depleted.
            _streams[streamId].isDepleted = true;

            // Effect: make the stream not cancelable anymore, because a depleted stream cannot be canceled.
            _streams[streamId].isCancelable = false;
        }

        // Retrieve the ERC-20 token from storage.
        IERC20 token = _streams[streamId].token;

        // Interaction: perform the ERC-20 transfer.
        token.safeTransfer({ to: to, value: amount });

        // Log the withdrawal.
        emit ISablierLockupBase.WithdrawFromLockupStream(streamId, to, token, amount);
    }
}
