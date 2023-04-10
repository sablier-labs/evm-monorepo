// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "../interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Lockup } from "../interfaces/ISablierV2Lockup.sol";
import { ISablierV2NFTDescriptor } from "../interfaces/ISablierV2NFTDescriptor.sol";
import { Errors } from "../libraries/Errors.sol";
import { Lockup } from "../types/DataTypes.sol";
import { SablierV2Base } from "./SablierV2Base.sol";
import { SablierV2FlashLoan } from "./SablierV2FlashLoan.sol";

/// @title SablierV2Lockup
/// @notice See the documentation in {ISablierV2Lockup}.
abstract contract SablierV2Lockup is
    SablierV2Base, // four dependencies
    ISablierV2Lockup, // four dependencies
    SablierV2FlashLoan // six dependencies
{
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
    /// @param initialNftDescriptor The address of the initial NFT descriptor.
    constructor(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        ISablierV2NFTDescriptor initialNftDescriptor
    )
        SablierV2Base(initialAdmin, initialComptroller)
    {
        _nftDescriptor = initialNftDescriptor;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `streamId` references an active stream.
    modifier isActive(uint256 streamId) {
        if (getStatus(streamId) != Lockup.Status.ACTIVE) {
            revert Errors.SablierV2Lockup_StreamNotActive(streamId);
        }
        _;
    }

    /// @dev Checks that `streamId` references a stream that is not null.
    modifier isNotNull(uint256 streamId) {
        if (getStatus(streamId) == Lockup.Status.NULL) {
            revert Errors.SablierV2Lockup_StreamNull(streamId);
        }
        _;
    }

    /// @notice Checks that `msg.sender` is either the stream's sender or the stream's recipient (i.e. the NFT owner).
    modifier onlySenderOrRecipient(uint256 streamId) {
        if (!_isCallerStreamSender(streamId) && msg.sender != _ownerOf(streamId)) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    function getStatus(uint256 streamId) public view virtual override returns (Lockup.Status status);

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    function burn(uint256 streamId) external override noDelegateCall {
        // Checks: the stream is depleted.
        if (getStatus(streamId) != Lockup.Status.DEPLETED) {
            revert Errors.SablierV2Lockup_StreamNotDepleted(streamId);
        }

        // Checks:
        // 1. NFT exists (see `getApproved`).
        // 2. `msg.sender` is either the owner of the NFT or an approved third party.
        if (!_isCallerStreamRecipientOrApproved(streamId)) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }

        // Effects: burn the NFT.
        _burn({ tokenId: streamId });
    }

    /// @inheritdoc ISablierV2Lockup
    function cancel(uint256 streamId)
        public
        override
        noDelegateCall
        isActive(streamId)
        onlySenderOrRecipient(streamId)
    {
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
    function renounce(uint256 streamId) external override noDelegateCall isActive(streamId) {
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
        isNotNull(streamId)
    {
        // Checks: the stream is not depleted.
        if (getStatus(streamId) == Lockup.Status.DEPLETED) {
            revert Errors.SablierV2Lockup_StreamDepleted(streamId);
        }

        // Checks: `msg.sender` is the stream's sender, the stream's recipient (i.e. the NFT owner), or an
        // approved third party.
        if (!_isCallerStreamSender(streamId) && !_isCallerStreamRecipientOrApproved(streamId)) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }

        // Checks: if `msg.sender` is the stream's sender, the withdrawal address must be the recipient.
        if (_isCallerStreamSender(streamId) && to != _ownerOf(streamId)) {
            revert Errors.SablierV2Lockup_WithdrawSenderUnauthorized(streamId, msg.sender, to);
        }

        // Checks: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierV2Lockup_WithdrawToZeroAddress();
        }

        // Checks: the withdraw amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2Lockup_WithdrawAmountZero(streamId);
        }

        // Checks: the withdraw amount is not greater than the withdrawable amount.
        uint128 withdrawableAmount = _withdrawableAmountOf(streamId);
        if (amount > withdrawableAmount) {
            revert Errors.SablierV2Lockup_WithdrawAmountGreaterThanWithdrawableAmount(
                streamId, amount, withdrawableAmount
            );
        }

        // Effects and Interactions: make the withdrawal.
        _withdraw(streamId, to, amount);
    }

    /// @inheritdoc ISablierV2Lockup
    function withdrawMax(uint256 streamId, address to) external override {
        withdraw(streamId, to, _withdrawableAmountOf(streamId));
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
        // Checks: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierV2Lockup_WithdrawToZeroAddress();
        }

        // Checks: there is an equal number of `streamIds` and `amounts`.
        uint256 streamIdsCount = streamIds.length;
        uint256 amountsCount = amounts.length;
        if (streamIdsCount != amountsCount) {
            revert Errors.SablierV2Lockup_WithdrawArrayCountsNotEqual(streamIdsCount, amountsCount);
        }

        // Iterate over the provided array of stream ids and withdraw from each stream.
        uint256 streamId;
        for (uint256 i = 0; i < streamIdsCount;) {
            streamId = streamIds[i];

            // Checks: the stream is neither null nor depleted.
            Lockup.Status status = getStatus(streamId);
            if (status == Lockup.Status.NULL) {
                revert Errors.SablierV2Lockup_StreamNull(streamId);
            } else if (status == Lockup.Status.DEPLETED) {
                revert Errors.SablierV2Lockup_StreamDepleted(streamId);
            }

            // Checks: `msg.sender` is the stream's recipient (i.e. the NFT owner) or an approved third party.
            if (!_isCallerStreamRecipientOrApproved(streamId)) {
                revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
            }

            // Checks: the withdraw amount is not zero.
            if (amounts[i] == 0) {
                revert Errors.SablierV2Lockup_WithdrawAmountZero(streamId);
            }

            // Checks: the withdraw amount is not greater than the withdrawable amount.
            uint128 withdrawableAmount = _withdrawableAmountOf(streamId);
            if (amounts[i] > withdrawableAmount) {
                revert Errors.SablierV2Lockup_WithdrawAmountGreaterThanWithdrawableAmount(
                    streamId, amounts[i], withdrawableAmount
                );
            }

            // Checks, Effects and Interactions: make the withdrawal.
            _withdraw(streamId, to, amounts[i]);

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
    function _isCallerStreamRecipientOrApproved(uint256 streamId) internal view virtual returns (bool result);

    /// @notice Checks whether `msg.sender` is the stream's sender.
    /// @param streamId The stream id for the query.
    function _isCallerStreamSender(uint256 streamId) internal view virtual returns (bool result);

    /// @notice Returns the owner of the NFT without reverting.
    /// @param tokenId The NFT id for the query.
    function _ownerOf(uint256 tokenId) internal view virtual returns (address owner);

    /// @dev See the documentation for the public functions that call this internal function.
    function _withdrawableAmountOf(uint256 streamId) internal view virtual returns (uint128 withdrawableAmount);

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the public functions that call this internal function.
    function _burn(uint256 tokenId) internal virtual;

    /// @dev See the documentation for the public functions that call this internal function.
    function _cancel(uint256 tokenId) internal virtual;

    /// @dev See the documentation for the public functions that call this internal function.
    function _renounce(uint256 streamId) internal virtual;

    /// @dev See the documentation for the public functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal virtual;
}
