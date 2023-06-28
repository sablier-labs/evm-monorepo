// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import { ISablierV2Comptroller } from "../interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Lockup } from "../interfaces/ISablierV2Lockup.sol";
import { ISablierV2NFTDescriptor } from "../interfaces/ISablierV2NFTDescriptor.sol";
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
    /*//////////////////////////////////////////////////////////////////////////
                                USER-FACING STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    uint256 public override nextStreamId;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Contract that generates the non-fungible token URI.
    ISablierV2NFTDescriptor internal _nftDescriptor;

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
        _nftDescriptor = initialNFTDescriptor;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `streamId` does not reference a null stream.
    modifier notNull(uint256 streamId) {
        if (!isStream(streamId)) {
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
    function getRecipient(uint256 streamId) external view override returns (address recipient) {
        // Checks: the stream NFT exists.
        _requireMinted({ tokenId: streamId });

        // The NFT owner is the stream's recipient.
        recipient = _ownerOf(streamId);
    }

    /// @inheritdoc ISablierV2Lockup
    function isDepleted(uint256 streamId) public view virtual override returns (bool result);

    /// @inheritdoc ISablierV2Lockup
    function isStream(uint256 streamId) public view virtual override returns (bool result);

    /// @inheritdoc ERC721
    function tokenURI(uint256 streamId) public view override(IERC721Metadata, ERC721) returns (string memory uri) {
        // Checks: the stream NFT exists.
        _requireMinted({ tokenId: streamId });

        // Generate the URI describing the stream NFT.
        uri = _nftDescriptor.tokenURI({ sablier: this, streamId: streamId });
    }

    /// @inheritdoc ISablierV2Lockup
    function wasCanceled(uint256 streamId) public view virtual override returns (bool result);

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
    function burn(uint256 streamId) external override noDelegateCall {
        // Checks: only depleted streams can be burned. This also checks that the stream is not null.
        if (!isDepleted(streamId)) {
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
    function cancel(uint256 streamId) public override noDelegateCall updateMetadata(streamId) {
        // Checks: the stream is neither depleted nor canceled. This also checks that the stream is not null.
        if (isDepleted(streamId)) {
            revert Errors.SablierV2Lockup_StreamDepleted(streamId);
        } else if (wasCanceled(streamId)) {
            revert Errors.SablierV2Lockup_StreamCanceled(streamId);
        }

        // Checks: `msg.sender` is either the stream's sender or the stream's recipient (i.e. the NFT owner).
        if (!_isCallerStreamSender(streamId) && msg.sender != _ownerOf(streamId)) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }

        // Checks, Effects and Interactions: cancel the stream.
        _cancel(streamId);
    }

    /// @inheritdoc ISablierV2Lockup
    function cancelMultiple(uint256[] calldata streamIds) external override noDelegateCall {
        // Iterate over the provided array of stream ids and cancel each stream.
        uint256 count = streamIds.length;
        for (uint256 i = 0; i < count;) {
            // Effects and Interactions: cancel the stream.
            cancel(streamIds[i]);

            // Increment the loop iterator.
            unchecked {
                i += 1;
            }
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

        // Effects: renounce the stream.
        _renounce(streamId);
    }

    /// @inheritdoc ISablierV2Lockup
    function setNFTDescriptor(ISablierV2NFTDescriptor newNFTDescriptor) external override onlyAdmin {
        // Effects: set the NFT descriptor.
        ISablierV2NFTDescriptor oldNftDescriptor = _nftDescriptor;
        _nftDescriptor = newNFTDescriptor;

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
        updateMetadata(streamId)
    {
        // Checks: the stream is not depleted. This also checks that the stream is not null.
        if (isDepleted(streamId)) {
            revert Errors.SablierV2Lockup_StreamDepleted(streamId);
        }

        // Checks: `msg.sender` is the stream's sender, the stream's recipient, or an approved third party.
        if (!_isCallerStreamSender(streamId) && !_isCallerStreamRecipientOrApproved(streamId)) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }

        // Checks: if `msg.sender` is the stream's sender, the withdrawal address must be the recipient.
        if (_isCallerStreamSender(streamId) && to != _ownerOf(streamId)) {
            revert Errors.SablierV2Lockup_InvalidSenderWithdrawal(streamId, msg.sender, to);
        }

        // Checks: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierV2Lockup_WithdrawToZeroAddress();
        }

        // Checks: the withdraw amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2Lockup_WithdrawAmountZero(streamId);
        }

        // Checks, Effects and Interactions: make the withdrawal.
        _withdraw(streamId, to, amount);
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
        updateMetadata(streamId)
    {
        // Checks: the caller is the current recipient. This also checks that the NFT was not burned.
        address currentRecipient = _ownerOf(streamId);
        if (msg.sender != currentRecipient) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }

        // Skip the withdrawal if the withdrawable amount is zero.
        uint128 withdrawableAmount = _withdrawableAmountOf(streamId);
        if (withdrawableAmount > 0) {
            _withdraw({ streamId: streamId, to: currentRecipient, amount: withdrawableAmount });
        }

        // Checks and Effects: transfer the NFT.
        _transfer({ from: currentRecipient, to: newRecipient, tokenId: streamId });
    }

    /// @inheritdoc ISablierV2Lockup
    function withdrawMultiple(
        uint256[] calldata streamIds,
        address to,
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
        for (uint256 i = 0; i < streamIdsCount;) {
            // Checks, Effects and Interactions: check the parameters and make the withdrawal.
            withdraw(streamIds[i], to, amounts[i]);

            // Increment the loop iterator.
            unchecked {
                i += 1;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether `msg.sender` is the stream's recipient or an approved third party.
    /// @param streamId The stream id for the query.
    function _isCallerStreamRecipientOrApproved(uint256 streamId) internal view returns (bool) {
        address recipient = _ownerOf(streamId);
        return msg.sender == recipient || isApprovedForAll({ owner: recipient, operator: msg.sender })
            || getApproved(streamId) == msg.sender;
    }

    /// @notice Checks whether `msg.sender` is the stream's sender.
    /// @param streamId The stream id for the query.
    function _isCallerStreamSender(uint256 streamId) internal view virtual returns (bool);

    /// @dev Retrieves the stream's status without performing a null check.
    function _statusOf(uint256 streamId) internal view virtual returns (Lockup.Status);

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _withdrawableAmountOf(uint256 streamId) internal view virtual returns (uint128);

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _cancel(uint256 tokenId) internal virtual;

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _renounce(uint256 streamId) internal virtual;

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal virtual;
}
