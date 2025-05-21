// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Batch } from "@sablier/evm-utils/src/Batch.sol";
import { NoDelegateCall } from "@sablier/evm-utils/src/NoDelegateCall.sol";
import { RoleAdminable } from "@sablier/evm-utils/src/RoleAdminable.sol";

import { SablierLockupState } from "./abstracts/SablierLockupState.sol";
import { ILockupNFTDescriptor } from "./interfaces/ILockupNFTDescriptor.sol";
import { ISablierLockup } from "./interfaces/ISablierLockup.sol";
import { ISablierLockupRecipient } from "./interfaces/ISablierLockupRecipient.sol";
import { Errors } from "./libraries/Errors.sol";
import { Helpers } from "./libraries/Helpers.sol";
import { LockupMath } from "./libraries/LockupMath.sol";
import { Lockup, LockupDynamic, LockupLinear, LockupTranched } from "./types/DataTypes.sol";
/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ██╗      ██████╗  ██████╗██╗  ██╗██╗   ██╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██║     ██╔═══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    ██║     ██║   ██║██║     █████╔╝ ██║   ██║██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ██║     ██║   ██║██║     ██╔═██╗ ██║   ██║██╔═══╝
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║    ███████╗╚██████╔╝╚██████╗██║  ██╗╚██████╔╝██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝

*/

/// @title SablierLockup
/// @notice See the documentation in {ISablierLockup}.
contract SablierLockup is
    Batch, // 1 inherited component
    ERC721, // 6 inherited components
    ISablierLockup, // 8 inherited components
    NoDelegateCall, // 0 inherited components
    RoleAdminable, // 3 inherited components
    SablierLockupState // 1 inherited component
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialNFTDescriptor The address of the NFT descriptor contract.
    constructor(
        address initialAdmin,
        address initialNFTDescriptor
    )
        ERC721("Sablier Lockup NFT", "SAB-LOCKUP")
        RoleAdminable(initialAdmin)
        SablierLockupState(initialNFTDescriptor)
    { }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockup
    function getRecipient(uint256 streamId) external view override returns (address recipient) {
        // Check the stream NFT exists and return the owner, which is the stream's recipient.
        recipient = _requireOwned({ tokenId: streamId });
    }

    /// @inheritdoc ISablierLockup
    function isCold(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        Lockup.Status status = _statusOf(streamId);
        result = status == Lockup.Status.SETTLED || status == Lockup.Status.CANCELED || status == Lockup.Status.DEPLETED;
    }

    /// @inheritdoc ISablierLockup
    function isWarm(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        Lockup.Status status = _statusOf(streamId);
        result = status == Lockup.Status.PENDING || status == Lockup.Status.STREAMING;
    }

    /// @inheritdoc ISablierLockup
    function refundableAmountOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 refundableAmount)
    {
        // Note that checking for `isCancelable` also checks if the stream `wasCanceled` thanks to the protocol
        // invariant that canceled streams are not cancelable anymore.
        if (_streams[streamId].isCancelable && !_streams[streamId].isDepleted) {
            refundableAmount = _streams[streamId].amounts.deposited - _streamedAmountOf(streamId);
        }
        // Otherwise, the result is implicitly zero.
    }

    /// @inheritdoc ISablierLockup
    function statusOf(uint256 streamId) external view override notNull(streamId) returns (Lockup.Status status) {
        status = _statusOf(streamId);
    }

    /// @inheritdoc ISablierLockup
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

    /// @inheritdoc ISablierLockup
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
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockup
    function allowToHook(address recipient) external override onlyAdmin {
        // Check: recipients implements the ERC-165 interface ID required by {ISablierLockupRecipient}.
        bytes4 interfaceId = type(ISablierLockupRecipient).interfaceId;
        if (!ISablierLockupRecipient(recipient).supportsInterface(interfaceId)) {
            revert Errors.SablierLockup_AllowToHookUnsupportedInterface(recipient);
        }

        // Effect: put the recipient on the allowlist.
        _allowedToHook[recipient] = true;

        // Log the allowlist addition.
        emit ISablierLockup.AllowToHook({ admin: msg.sender, recipient: recipient });
    }

    /// @inheritdoc ISablierLockup
    function burn(uint256 streamId) external payable override noDelegateCall notNull(streamId) {
        // Check: only depleted streams can be burned.
        if (!_streams[streamId].isDepleted) {
            revert Errors.SablierLockup_StreamNotDepleted(streamId);
        }

        // Retrieve the current owner.
        address currentRecipient = _ownerOf(streamId);

        // Check: `msg.sender` is either the owner of the NFT or an approved third party.
        if (!_isCallerStreamRecipientOrApproved(streamId, currentRecipient)) {
            revert Errors.SablierLockup_Unauthorized(streamId, msg.sender);
        }

        // Effect: burn the NFT.
        _burn({ tokenId: streamId });
    }

    /// @inheritdoc ISablierLockup
    function cancel(uint256 streamId)
        public
        payable
        override
        noDelegateCall
        notNull(streamId)
        returns (uint128 refundedAmount)
    {
        // Check: the stream is neither depleted nor canceled.
        if (_streams[streamId].isDepleted) {
            revert Errors.SablierLockup_StreamDepleted(streamId);
        } else if (_streams[streamId].wasCanceled) {
            revert Errors.SablierLockup_StreamCanceled(streamId);
        }

        // Check: `msg.sender` is the stream's sender.
        if (msg.sender != _streams[streamId].sender) {
            revert Errors.SablierLockup_Unauthorized(streamId, msg.sender);
        }

        // Checks, Effects and Interactions: cancel the stream.
        refundedAmount = _cancel(streamId);
    }

    /// @inheritdoc ISablierLockup
    function cancelMultiple(uint256[] calldata streamIds)
        external
        payable
        override
        noDelegateCall
        returns (uint128[] memory refundedAmounts)
    {
        uint256 count = streamIds.length;

        // Initialize the refunded amounts array.
        refundedAmounts = new uint128[](count);

        // Iterate over the provided array of stream IDs and cancel each stream.
        for (uint256 i = 0; i < count; ++i) {
            // Checks, Effects and Interactions: cancel the stream using a delegate call to self.
            (bool success, bytes memory result) =
                address(this).delegatecall(abi.encodeCall(ISablierLockup.cancel, (streamIds[i])));

            // If there is a revert, log it using an event, and continue with the next stream.
            if (!success) {
                emit ISablierLockup.InvalidStreamInCancelMultiple(streamIds[i], result);
            }
            // Otherwise, the call is successful, so insert the refunded amount into the array.
            else {
                // Update the amounts array.
                refundedAmounts[i] = abi.decode(result, (uint128));
            }
        }
    }

    /// @inheritdoc ISablierLockup
    function collectFees(address feeRecipient) external override {
        // Check: if `msg.sender` has neither the {RoleAdminable.FEE_COLLECTOR_ROLE} role nor is the contract admin,
        // then `feeRecipient` must be the admin address.
        bool hasRoleOrIsAdmin = _hasRoleOrIsAdmin({ role: FEE_COLLECTOR_ROLE, account: msg.sender });
        if (!hasRoleOrIsAdmin && feeRecipient != admin) {
            revert Errors.SablierLockup_FeeRecipientNotAdmin({ feeRecipient: feeRecipient, admin: admin });
        }

        uint256 feeAmount = address(this).balance;

        // Effect: transfer the fees to the fee recipient.
        (bool success,) = feeRecipient.call{ value: feeAmount }("");

        // Check: the transfer was successful.
        if (!success) {
            revert Errors.SablierLockup_FeeTransferFail(feeRecipient, feeAmount);
        }

        // Log the fee withdrawal.
        emit ISablierLockup.CollectFees(admin, feeRecipient, feeAmount);
    }

    /// @inheritdoc ISablierLockup
    function createWithDurationsLD(
        Lockup.CreateWithDurations calldata params,
        LockupDynamic.SegmentWithDuration[] calldata segmentsWithDuration
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Use the block timestamp as the start time.
        uint40 startTime = uint40(block.timestamp);

        // Generate the canonical segments.
        LockupDynamic.Segment[] memory segments = Helpers.calculateSegmentTimestamps(segmentsWithDuration, startTime);

        // Declare the timestamps for the stream.
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: startTime, end: segments[segments.length - 1].timestamp });

        // Checks, Effects and Interactions: create the stream.
        streamId = _createLD({
            cancelable: params.cancelable,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            segments: segments,
            sender: params.sender,
            shape: params.shape,
            timestamps: timestamps,
            token: params.token,
            transferable: params.transferable
        });
    }

    /// @inheritdoc ISablierLockup
    function createWithDurationsLL(
        Lockup.CreateWithDurations calldata params,
        LockupLinear.UnlockAmounts calldata unlockAmounts,
        LockupLinear.Durations calldata durations
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Set the current block timestamp as the stream's start time.
        Lockup.Timestamps memory timestamps = Lockup.Timestamps({ start: uint40(block.timestamp), end: 0 });

        uint40 cliffTime;

        // Calculate the cliff time and the end time.
        if (durations.cliff > 0) {
            cliffTime = timestamps.start + durations.cliff;
        }
        timestamps.end = timestamps.start + durations.total;

        // Checks, Effects and Interactions: create the stream.
        streamId = _createLL({
            cancelable: params.cancelable,
            cliffTime: cliffTime,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            sender: params.sender,
            shape: params.shape,
            timestamps: timestamps,
            token: params.token,
            transferable: params.transferable,
            unlockAmounts: unlockAmounts
        });
    }

    /// @inheritdoc ISablierLockup
    function createWithDurationsLT(
        Lockup.CreateWithDurations calldata params,
        LockupTranched.TrancheWithDuration[] calldata tranchesWithDuration
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Use the block timestamp as the start time.
        uint40 startTime = uint40(block.timestamp);

        // Generate the canonical tranches.
        LockupTranched.Tranche[] memory tranches = Helpers.calculateTrancheTimestamps(tranchesWithDuration, startTime);

        // Declare the timestamps for the stream.
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: startTime, end: tranches[tranches.length - 1].timestamp });

        // Checks, Effects and Interactions: create the stream.
        streamId = _createLT({
            cancelable: params.cancelable,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            sender: params.sender,
            shape: params.shape,
            timestamps: timestamps,
            token: params.token,
            tranches: tranches,
            transferable: params.transferable
        });
    }

    /// @inheritdoc ISablierLockup
    function createWithTimestampsLD(
        Lockup.CreateWithTimestamps calldata params,
        LockupDynamic.Segment[] calldata segments
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _createLD({
            cancelable: params.cancelable,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            segments: segments,
            sender: params.sender,
            shape: params.shape,
            timestamps: params.timestamps,
            token: params.token,
            transferable: params.transferable
        });
    }

    /// @inheritdoc ISablierLockup
    function createWithTimestampsLL(
        Lockup.CreateWithTimestamps calldata params,
        LockupLinear.UnlockAmounts calldata unlockAmounts,
        uint40 cliffTime
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _createLL({
            cancelable: params.cancelable,
            cliffTime: cliffTime,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            sender: params.sender,
            shape: params.shape,
            timestamps: params.timestamps,
            token: params.token,
            transferable: params.transferable,
            unlockAmounts: unlockAmounts
        });
    }

    /// @inheritdoc ISablierLockup
    function createWithTimestampsLT(
        Lockup.CreateWithTimestamps calldata params,
        LockupTranched.Tranche[] calldata tranches
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _createLT({
            cancelable: params.cancelable,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            sender: params.sender,
            shape: params.shape,
            timestamps: params.timestamps,
            token: params.token,
            tranches: tranches,
            transferable: params.transferable
        });
    }

    /// @inheritdoc ISablierLockup
    function recover(IERC20 token, address to) external override onlyAdmin {
        // If tokens are directly transferred to the contract without using the stream creation functions, the
        // ERC-20 balance may be greater than the aggregate amount.
        uint256 surplus = token.balanceOf(address(this)) - aggregateAmount[token];

        // Interaction: transfer the surplus to the provided address.
        token.safeTransfer({ to: to, value: surplus });
    }

    /// @inheritdoc ISablierLockup
    function renounce(uint256 streamId) public payable override noDelegateCall notNull(streamId) {
        // Check: the stream is not cold.
        Lockup.Status status = _statusOf(streamId);
        if (status == Lockup.Status.DEPLETED) {
            revert Errors.SablierLockup_StreamDepleted(streamId);
        } else if (status == Lockup.Status.CANCELED) {
            revert Errors.SablierLockup_StreamCanceled(streamId);
        } else if (status == Lockup.Status.SETTLED) {
            revert Errors.SablierLockup_StreamSettled(streamId);
        }

        // Check: `msg.sender` is the stream's sender.
        if (msg.sender != _streams[streamId].sender) {
            revert Errors.SablierLockup_Unauthorized(streamId, msg.sender);
        }

        // Check: the stream is cancelable.
        if (!_streams[streamId].isCancelable) {
            revert Errors.SablierLockup_StreamNotCancelable(streamId);
        }

        // Effect: renounce the stream by making it not cancelable.
        _streams[streamId].isCancelable = false;

        // Log the renouncement.
        emit ISablierLockup.RenounceLockupStream(streamId);
    }

    /// @inheritdoc ISablierLockup
    function setNativeToken(address newNativeToken) external override onlyAdmin {
        // Check: native token is not set.
        if (nativeToken != address(0)) {
            revert Errors.SablierLockup_NativeTokenAlreadySet(nativeToken);
        }

        // Effect: set the native token.
        nativeToken = newNativeToken;
    }

    /// @inheritdoc ISablierLockup
    function setNFTDescriptor(ILockupNFTDescriptor newNFTDescriptor) external override onlyAdmin {
        // Effect: set the NFT descriptor.
        ILockupNFTDescriptor oldNftDescriptor = nftDescriptor;
        nftDescriptor = newNFTDescriptor;

        // Log the change of the NFT descriptor.
        emit ISablierLockup.SetNFTDescriptor({
            admin: msg.sender,
            oldNFTDescriptor: oldNftDescriptor,
            newNFTDescriptor: newNFTDescriptor
        });

        // Refresh the NFT metadata for all streams.
        emit IERC4906.BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: nextStreamId - 1 });
    }

    /// @inheritdoc ISablierLockup
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
            revert Errors.SablierLockup_StreamDepleted(streamId);
        }

        // Check: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierLockup_WithdrawToZeroAddress(streamId);
        }

        // Retrieve the recipient from storage.
        address recipient = _ownerOf(streamId);

        // Check: if `msg.sender` is neither the stream's recipient nor an approved third party, the withdrawal address
        // must be the recipient.
        if (to != recipient && !_isCallerStreamRecipientOrApproved(streamId, recipient)) {
            revert Errors.SablierLockup_WithdrawalAddressNotRecipient(streamId, msg.sender, to);
        }

        // Check: the withdraw amount is not zero.
        if (amount == 0) {
            revert Errors.SablierLockup_WithdrawAmountZero(streamId);
        }

        // Check: the withdraw amount is not greater than the withdrawable amount.
        uint128 withdrawableAmount = _withdrawableAmountOf(streamId);
        if (amount > withdrawableAmount) {
            revert Errors.SablierLockup_Overdraw(streamId, amount, withdrawableAmount);
        }

        // Effects and Interactions: make the withdrawal.
        _withdraw(streamId, to, amount);

        // Emit an ERC-4906 event to trigger an update of the NFT metadata.
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

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
                revert Errors.SablierLockup_InvalidHookSelector(recipient);
            }
        }
    }

    /// @inheritdoc ISablierLockup
    function withdrawMax(uint256 streamId, address to) external payable override returns (uint128 withdrawnAmount) {
        withdrawnAmount = _withdrawableAmountOf(streamId);
        withdraw({ streamId: streamId, to: to, amount: withdrawnAmount });
    }

    /// @inheritdoc ISablierLockup
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

        // Check: `msg.sender` is either the stream's recipient or an approved third party.
        if (!_isCallerStreamRecipientOrApproved(streamId, currentRecipient)) {
            revert Errors.SablierLockup_Unauthorized(streamId, msg.sender);
        }

        // Skip the withdrawal if the withdrawable amount is zero.
        withdrawnAmount = _withdrawableAmountOf(streamId);
        if (withdrawnAmount > 0) {
            withdraw({ streamId: streamId, to: currentRecipient, amount: withdrawnAmount });
        }

        // Checks and Effects: transfer the NFT.
        _transfer({ from: currentRecipient, to: newRecipient, tokenId: streamId });
    }

    /// @inheritdoc ISablierLockup
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
            revert Errors.SablierLockup_WithdrawArrayCountsNotEqual(streamIdsCount, amountsCount);
        }

        // Iterate over the provided array of stream IDs and withdraw from each stream to the recipient.
        for (uint256 i = 0; i < streamIdsCount; ++i) {
            // Checks, Effects and Interactions: withdraw using a delegate call to self.
            (bool success, bytes memory result) = address(this).delegatecall(
                abi.encodeCall(ISablierLockup.withdraw, (streamIds[i], _ownerOf(streamIds[i]), amounts[i]))
            );
            // If there is a revert, log it using an event, and continue with the next stream.
            if (!success) {
                emit ISablierLockup.InvalidWithdrawalInWithdrawMultiple(streamIds[i], result);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierLockupState
    function _streamedAmountOf(uint256 streamId) internal view override returns (uint128 streamedAmount) {
        // Load the stream from storage.
        Lockup.Stream memory stream = _streams[streamId];

        if (stream.isDepleted) {
            return stream.amounts.withdrawn;
        } else if (stream.wasCanceled) {
            return stream.amounts.deposited - stream.amounts.refunded;
        }

        // Calculate the streamed amount for the LD model.
        if (stream.lockupModel == Lockup.Model.LOCKUP_DYNAMIC) {
            streamedAmount = LockupMath.calculateStreamedAmountLD({
                depositedAmount: stream.amounts.deposited,
                endTime: stream.endTime,
                segments: _segments[streamId],
                startTime: stream.startTime,
                withdrawnAmount: stream.amounts.withdrawn
            });
        }
        // Calculate the streamed amount for the LL model.
        else if (stream.lockupModel == Lockup.Model.LOCKUP_LINEAR) {
            streamedAmount = LockupMath.calculateStreamedAmountLL({
                cliffTime: _cliffs[streamId],
                depositedAmount: stream.amounts.deposited,
                endTime: stream.endTime,
                startTime: stream.startTime,
                unlockAmounts: _unlockAmounts[streamId],
                withdrawnAmount: stream.amounts.withdrawn
            });
        }
        // Calculate the streamed amount for the LT model.
        else if (stream.lockupModel == Lockup.Model.LOCKUP_TRANCHED) {
            streamedAmount = LockupMath.calculateStreamedAmountLT({
                depositedAmount: stream.amounts.deposited,
                endTime: stream.endTime,
                startTime: stream.startTime,
                tranches: _tranches[streamId]
            });
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                         INTERNAL STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

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
            revert Errors.SablierLockup_NotTransferable(streamId);
        }

        // Emit an ERC-4906 event to trigger an update of the NFT metadata.
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        return super._update(to, streamId, auth);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether `msg.sender` is the stream's recipient or an approved third party, when the `recipient`
    /// is known in advance.
    /// @param streamId The stream ID for the query.
    /// @param recipient The address of the stream's recipient.
    function _isCallerStreamRecipientOrApproved(uint256 streamId, address recipient) private view returns (bool) {
        return _isAuthorized({ owner: recipient, spender: msg.sender, tokenId: streamId });
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _withdrawableAmountOf(uint256 streamId) private view returns (uint128) {
        return _streamedAmountOf(streamId) - _streams[streamId].amounts.withdrawn;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _cancel(uint256 streamId) private returns (uint128 senderAmount) {
        // Calculate the streamed amount.
        uint128 streamedAmount = _streamedAmountOf(streamId);

        // Retrieve the amounts from storage.
        Lockup.Amounts memory amounts = _streams[streamId].amounts;

        // Check: the stream is not settled.
        if (streamedAmount >= amounts.deposited) {
            revert Errors.SablierLockup_StreamSettled(streamId);
        }

        // Check: the stream is cancelable.
        if (!_streams[streamId].isCancelable) {
            revert Errors.SablierLockup_StreamNotCancelable(streamId);
        }

        // Calculate the sender's amount.
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

        unchecked {
            // Effect: decrease the aggregate amount.
            aggregateAmount[token] -= senderAmount;
        }

        // Interaction: refund the sender.
        token.safeTransfer({ to: sender, value: senderAmount });

        // Log the cancellation.
        emit ISablierLockup.CancelLockupStream(streamId, sender, recipient, token, senderAmount, recipientAmount);

        // Emit an ERC-4906 event to trigger an update of the NFT metadata.
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

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
                revert Errors.SablierLockup_InvalidHookSelector(recipient);
            }
        }
    }

    /// @dev Common logic for creating a stream.
    function _create(
        bool cancelable,
        uint128 depositAmount,
        Lockup.Model lockupModel,
        address recipient,
        address sender,
        uint256 streamId,
        Lockup.Timestamps memory timestamps,
        IERC20 token,
        bool transferable
    )
        private
    {
        // Effect: create the stream.
        _streams[streamId] = Lockup.Stream({
            sender: sender,
            startTime: timestamps.start,
            endTime: timestamps.end,
            isCancelable: cancelable,
            wasCanceled: false,
            token: token,
            isDepleted: false,
            isTransferable: transferable,
            lockupModel: lockupModel,
            amounts: Lockup.Amounts({ deposited: depositAmount, withdrawn: 0, refunded: 0 })
        });

        // Effect: mint the NFT to the recipient.
        _mint({ to: recipient, tokenId: streamId });

        unchecked {
            // Effect: bump the next stream ID.
            nextStreamId = streamId + 1;

            // Effect: increase the aggregate amount.
            aggregateAmount[token] += depositAmount;
        }

        // Interaction: transfer the deposit amount.
        token.safeTransferFrom({ from: msg.sender, to: address(this), value: depositAmount });
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _createLD(
        bool cancelable,
        uint128 depositAmount,
        address recipient,
        LockupDynamic.Segment[] memory segments,
        address sender,
        string memory shape,
        Lockup.Timestamps memory timestamps,
        IERC20 token,
        bool transferable
    )
        private
        returns (uint256 streamId)
    {
        // Check: validate the user-provided parameters and segments.
        Helpers.checkCreateLD({
            sender: sender,
            timestamps: timestamps,
            depositAmount: depositAmount,
            segments: segments,
            token: address(token),
            nativeToken: nativeToken,
            shape: shape
        });

        // Load the stream ID in a variable.
        streamId = nextStreamId;

        // Effect: store the segments. Since Solidity lacks a syntax for copying arrays of structs directly from
        // memory to storage, a manual approach is necessary. See https://github.com/ethereum/solidity/issues/12783.
        uint256 segmentCount = segments.length;
        for (uint256 i = 0; i < segmentCount; ++i) {
            _segments[streamId].push(segments[i]);
        }

        // Effect: create the stream, mint the NFT and transfer the deposit amount.
        _create({
            cancelable: cancelable,
            depositAmount: depositAmount,
            lockupModel: Lockup.Model.LOCKUP_DYNAMIC,
            recipient: recipient,
            sender: sender,
            streamId: streamId,
            timestamps: timestamps,
            token: token,
            transferable: transferable
        });

        // Log the newly created stream.
        emit ISablierLockup.CreateLockupDynamicStream({
            streamId: streamId,
            commonParams: Lockup.CreateEventCommon({
                sender: sender,
                recipient: recipient,
                depositAmount: depositAmount,
                token: token,
                cancelable: cancelable,
                transferable: transferable,
                timestamps: timestamps,
                shape: shape
            }),
            segments: segments
        });
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _createLL(
        bool cancelable,
        uint40 cliffTime,
        uint128 depositAmount,
        address recipient,
        address sender,
        string memory shape,
        Lockup.Timestamps memory timestamps,
        IERC20 token,
        bool transferable,
        LockupLinear.UnlockAmounts memory unlockAmounts
    )
        private
        returns (uint256 streamId)
    {
        // Check: validate the user-provided parameters and cliff time.
        Helpers.checkCreateLL({
            sender: sender,
            timestamps: timestamps,
            cliffTime: cliffTime,
            depositAmount: depositAmount,
            unlockAmounts: unlockAmounts,
            token: address(token),
            nativeToken: nativeToken,
            shape: shape
        });

        // Load the stream ID in a variable.
        streamId = nextStreamId;

        // Effect: set the start and cliff unlock amounts.
        _unlockAmounts[streamId] = unlockAmounts;

        // Effect: update cliff time.
        _cliffs[streamId] = cliffTime;

        // Effect: create the stream, mint the NFT and transfer the deposit amount.
        _create({
            cancelable: cancelable,
            depositAmount: depositAmount,
            lockupModel: Lockup.Model.LOCKUP_LINEAR,
            recipient: recipient,
            sender: sender,
            streamId: streamId,
            timestamps: timestamps,
            token: token,
            transferable: transferable
        });

        // Log the newly created stream.
        emit ISablierLockup.CreateLockupLinearStream({
            streamId: streamId,
            commonParams: Lockup.CreateEventCommon({
                sender: sender,
                recipient: recipient,
                depositAmount: depositAmount,
                token: token,
                cancelable: cancelable,
                transferable: transferable,
                timestamps: timestamps,
                shape: shape
            }),
            cliffTime: cliffTime,
            unlockAmounts: unlockAmounts
        });
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _createLT(
        bool cancelable,
        uint128 depositAmount,
        address recipient,
        address sender,
        string memory shape,
        Lockup.Timestamps memory timestamps,
        IERC20 token,
        bool transferable,
        LockupTranched.Tranche[] memory tranches
    )
        private
        returns (uint256 streamId)
    {
        // Check: validate the user-provided parameters and tranches.
        Helpers.checkCreateLT({
            sender: sender,
            timestamps: timestamps,
            depositAmount: depositAmount,
            tranches: tranches,
            token: address(token),
            nativeToken: nativeToken,
            shape: shape
        });

        // Load the stream ID in a variable.
        streamId = nextStreamId;

        // Effect: store the tranches. Since Solidity lacks a syntax for copying arrays of structs directly from
        // memory to storage, a manual approach is necessary. See https://github.com/ethereum/solidity/issues/12783.
        uint256 trancheCount = tranches.length;
        for (uint256 i = 0; i < trancheCount; ++i) {
            _tranches[streamId].push(tranches[i]);
        }

        // Effect: create the stream, mint the NFT and transfer the deposit amount.
        _create({
            cancelable: cancelable,
            depositAmount: depositAmount,
            lockupModel: Lockup.Model.LOCKUP_TRANCHED,
            recipient: recipient,
            sender: sender,
            streamId: streamId,
            timestamps: timestamps,
            token: token,
            transferable: transferable
        });

        // Log the newly created stream.
        emit ISablierLockup.CreateLockupTranchedStream({
            streamId: streamId,
            commonParams: Lockup.CreateEventCommon({
                sender: sender,
                recipient: recipient,
                depositAmount: depositAmount,
                token: token,
                cancelable: cancelable,
                transferable: transferable,
                timestamps: timestamps,
                shape: shape
            }),
            tranches: tranches
        });
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _withdraw(uint256 streamId, address to, uint128 amount) private {
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

        unchecked {
            // Effect: decrease the aggregate amount.
            aggregateAmount[token] -= amount;
        }

        // Interaction: perform the ERC-20 transfer.
        token.safeTransfer({ to: to, value: amount });

        // Log the withdrawal.
        emit ISablierLockup.WithdrawFromLockupStream(streamId, to, token, amount);
    }
}
