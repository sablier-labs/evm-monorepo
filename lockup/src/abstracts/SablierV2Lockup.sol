// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "../interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Lockup } from "../interfaces/ISablierV2Lockup.sol";
import { Errors } from "../libraries/Errors.sol";
import { Status } from "../types/Enums.sol";
import { SablierV2Config } from "./SablierV2Config.sol";
import { SablierV2FlashLoan } from "./SablierV2FlashLoan.sol";

/// @title SablierV2Lockup
/// @dev Abstract contract that implements the {ISablierV2Lockup} interface and other common logic.
abstract contract SablierV2Lockup is
    SablierV2Config, // three dependencies
    ISablierV2Lockup, // four dependencies
    SablierV2FlashLoan // five dependencies
{
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    uint256 public override nextStreamId;

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `streamId` points to an active stream.
    modifier isActiveStream(uint256 streamId) {
        if (getStatus(streamId) != Status.ACTIVE) {
            revert Errors.SablierV2Lockup_StreamNotActive(streamId);
        }
        _;
    }

    /// @notice Checks that `msg.sender` is the sender of the stream, the recipient of the stream (also known as
    /// the owner of the NFT), or an approved operator.
    modifier isAuthorizedForStream(uint256 streamId) {
        if (!_isCallerStreamSender(streamId) && !_isApprovedOrOwner(streamId, msg.sender)) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /// @notice Checks that `msg.sender` is either the sender of the stream or the recipient of the stream (also known
    /// as the owner of the NFT).
    modifier onlySenderOrRecipient(uint256 streamId) {
        if (!_isCallerStreamSender(streamId) && msg.sender != getRecipient(streamId)) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialComptroller The address of the initial comptroller.
    /// @param maxFee The maximum fee that can be charged by either the protocol or a broker, as an UD60x18 number
    /// where 100% = 1e18.
    constructor(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        UD60x18 maxFee
    ) SablierV2Config(initialAdmin, initialComptroller, maxFee) {
        nextStreamId = 1;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    function getRecipient(uint256 streamId) public view virtual override returns (address recipient);

    /// @inheritdoc ISablierV2Lockup
    function getStatus(uint256 streamId) public view virtual override returns (Status status);

    /// @inheritdoc ISablierV2Lockup
    function getWithdrawableAmount(uint256 streamId) public view virtual override returns (uint128 withdrawableAmount);

    /// @inheritdoc ISablierV2Lockup
    function isCancelable(uint256 streamId) public view virtual override returns (bool result);

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    function burn(uint256 streamId) external override {
        // Checks: the stream is either canceled or depleted.
        Status status = getStatus(streamId);
        if (status != Status.CANCELED && status != Status.DEPLETED) {
            revert Errors.SablierV2Lockup_StreamNotCanceledOrDepleted(streamId);
        }

        // Checks: the `msg.sender` is either the owner of the NFT or an approved operator.
        if (!_isApprovedOrOwner(streamId, msg.sender)) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }

        // Effects: burn the NFT.
        _burn({ tokenId: streamId });
    }

    /// @inheritdoc ISablierV2Lockup
    function cancel(uint256 streamId) external override isActiveStream(streamId) {
        // Checks: the stream is cancelable.
        if (!isCancelable(streamId)) {
            revert Errors.SablierV2Lockup_StreamNonCancelable(streamId);
        }

        // Effects and Interactions: cancel the stream.
        _cancel(streamId);
    }

    /// @inheritdoc ISablierV2Lockup
    function cancelMultiple(uint256[] calldata streamIds) external override {
        // Iterate over the provided array of stream ids and cancel each stream.
        uint256 count = streamIds.length;
        uint256 streamId;
        for (uint256 i = 0; i < count; ) {
            streamId = streamIds[i];

            // Effects and Interactions: cancel the stream.
            // CancelLockupStream this stream only if the `streamId` points to a stream that is active and cancelable.
            if (getStatus(streamId) == Status.ACTIVE && isCancelable(streamId)) {
                _cancel(streamId);
            }

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }
    }

    /// @inheritdoc ISablierV2Lockup
    function renounce(uint256 streamId) external override isActiveStream(streamId) {
        // Checks: the `msg.sender` is the sender of the stream.
        if (!_isCallerStreamSender(streamId)) {
            revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
        }

        // Checks: the stream is cancelable.
        if (!isCancelable(streamId)) {
            revert Errors.SablierV2Lockup_RenounceNonCancelableStream(streamId);
        }

        // Effects: renounce the stream.
        _renounce(streamId);
    }

    /// @inheritdoc ISablierV2Lockup
    function withdraw(
        uint256 streamId,
        address to,
        uint128 amount
    ) public override isActiveStream(streamId) isAuthorizedForStream(streamId) {
        // Checks: the provided address is the recipient if `msg.sender` is the sender of the stream.
        if (_isCallerStreamSender(streamId) && to != getRecipient(streamId)) {
            revert Errors.SablierV2Lockup_WithdrawSenderUnauthorized(streamId, msg.sender, to);
        }

        // Checks: the provided withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierV2Lockup_WithdrawToZeroAddress();
        }

        // Checks, Effects and Interactions: make the withdrawal.
        _withdraw(streamId, to, amount);
    }

    /// @inheritdoc ISablierV2Lockup
    function withdrawMax(uint256 streamId, address to) external override {
        withdraw(streamId, to, getWithdrawableAmount(streamId));
    }

    /// @inheritdoc ISablierV2Lockup
    function withdrawMultiple(uint256[] calldata streamIds, address to, uint128[] calldata amounts) external override {
        // Checks: the provided address to withdraw to is not zero.
        if (to == address(0)) {
            revert Errors.SablierV2Lockup_WithdrawToZeroAddress();
        }

        // Checks: count of `streamIds` matches count of `amounts`.
        uint256 streamIdsCount = streamIds.length;
        uint256 amountsCount = amounts.length;
        if (streamIdsCount != amountsCount) {
            revert Errors.SablierV2Lockup_WithdrawArraysNotEqual(streamIdsCount, amountsCount);
        }

        // Iterate over the provided array of stream ids and withdraw from each stream.
        uint256 streamId;
        for (uint256 i = 0; i < streamIdsCount; ) {
            streamId = streamIds[i];

            // If the `streamId` does not point to an active stream, simply skip it.
            if (getStatus(streamId) == Status.ACTIVE) {
                // Checks: the `msg.sender` is an approved operator or the owner of the NFT (also known as the recipient
                // of the stream).
                if (!_isApprovedOrOwner(streamId, msg.sender)) {
                    revert Errors.SablierV2Lockup_Unauthorized(streamId, msg.sender);
                }

                // Checks, Effects and Interactions: make the withdrawal.
                _withdraw(streamId, to, amounts[i]);
            }

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether the spender is authorized to interact with the stream.
    /// @dev Unlike the ERC-721 implementation, this function does not check whether the owner is the zero address.
    /// @param streamId The id of the stream to make the query for.
    /// @param spender The spender to make the query for.
    function _isApprovedOrOwner(
        uint256 streamId,
        address spender
    ) internal view virtual returns (bool isApprovedOrOwner);

    /// @notice Checks whether the `msg.sender` is the sender of the stream or not.
    /// @param streamId The id of the stream to make the query for.
    /// @return result Whether the `msg.sender` is the sender of the stream or not.
    function _isCallerStreamSender(uint256 streamId) internal view virtual returns (bool result);

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the public functions that call this internal function.
    function _burn(uint256 tokenId) internal virtual;

    /// @dev See the documentation for the public functions that call this internal function.
    function _cancel(uint256 streamId) internal virtual;

    /// @dev See the documentation for the public functions that call this internal function.
    function _renounce(uint256 streamId) internal virtual;

    /// @dev See the documentation for the public functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal virtual;
}
