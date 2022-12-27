// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { Errors } from "./libraries/Errors.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";

/// @title SablierV2
/// @dev Abstract contract implementing common logic. Implements the ISablierV2 interface.
abstract contract SablierV2 is ISablierV2 {
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2
    uint256 public override nextStreamId;

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks that `msg.sender` is the sender of the stream, an approved operator, or the owner of the
    /// NFT (also known as the recipient of the stream).
    modifier isAuthorizedForStream(uint256 streamId) {
        if (!_isCallerStreamSender(streamId) && !_isApprovedOrOwner(streamId, msg.sender)) {
            revert Errors.SablierV2__Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /// @notice Checks that `msg.sender` is either the sender of the stream or the owner of the NFT (also known as
    /// the recipient of the stream).
    modifier onlySenderOrRecipient(uint256 streamId) {
        if (!_isCallerStreamSender(streamId) && msg.sender != getRecipient(streamId)) {
            revert Errors.SablierV2__Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /// @dev Checks that `streamId` points to a stream that exists.
    modifier streamExists(uint256 streamId) {
        if (!isEntity(streamId)) {
            revert Errors.SablierV2__StreamNonExistent(streamId);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        nextStreamId = 1;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2
    function getRecipient(uint256 streamId) public view virtual override returns (address recipient);

    /// @inheritdoc ISablierV2
    function isCancelable(uint256 streamId) public view virtual override returns (bool result);

    /// @inheritdoc ISablierV2
    function isEntity(uint256 streamId) public view virtual override returns (bool result);

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2
    function burn(uint256 streamId) external override {
        // Checks: the stream does not exist.
        if (isEntity(streamId)) {
            revert Errors.SablierV2__StreamExistent(streamId);
        }

        // Checks:
        // 1. The NFT exists (see `getApproved`).
        // 2. The `msg.sender` is either the owner of the NFT or an approved operator.
        if (!_isApprovedOrOwner(streamId, msg.sender)) {
            revert Errors.SablierV2__Unauthorized(streamId, msg.sender);
        }

        // Effects: burn the NFT.
        _burn({ tokenId: streamId });
    }

    /// @inheritdoc ISablierV2
    function cancel(uint256 streamId) external override streamExists(streamId) {
        // Checks: the stream is cancelable.
        if (!isCancelable(streamId)) {
            revert Errors.SablierV2__StreamNonCancelable(streamId);
        }

        _cancel(streamId);
    }

    /// @inheritdoc ISablierV2
    function cancelAll(uint256[] calldata streamIds) external override {
        // Iterate over the provided array of stream ids and cancel each stream that exists and is cancelable.
        uint256 count = streamIds.length;
        uint256 streamId;
        for (uint256 i = 0; i < count; ) {
            streamId = streamIds[i];

            // Cancel the stream only if the `streamId` points to a stream that exists and is cancelable.
            if (isEntity(streamId) && isCancelable(streamId)) {
                _cancel(streamId);
            }

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }
    }

    /// @inheritdoc ISablierV2
    function renounce(uint256 streamId) external override streamExists(streamId) {
        // Checks: the `msg.sender` is the sender of the stream.
        if (!_isCallerStreamSender(streamId)) {
            revert Errors.SablierV2__Unauthorized(streamId, msg.sender);
        }

        // Checks: the stream is cancelable.
        if (!isCancelable(streamId)) {
            revert Errors.SablierV2__RenounceNonCancelableStream(streamId);
        }

        _renounce(streamId);
    }

    /// @inheritdoc ISablierV2
    function withdraw(
        uint256 streamId,
        address to,
        uint128 amount
    ) external override streamExists(streamId) isAuthorizedForStream(streamId) {
        // Checks: the provided address is the recipient if `msg.sender` is the sender of the stream.
        if (_isCallerStreamSender(streamId) && to != getRecipient(streamId)) {
            revert Errors.SablierV2__WithdrawSenderUnauthorized(streamId, msg.sender, to);
        }

        // Checks: the provided address to withdraw to is not zero.
        if (to == address(0)) {
            revert Errors.SablierV2__WithdrawToZeroAddress();
        }

        // Checks, Effects and Interactions: make the withdrawal.
        _withdraw(streamId, to, amount);
    }

    /// @inheritdoc ISablierV2
    function withdrawAll(uint256[] calldata streamIds, address to, uint128[] calldata amounts) external override {
        // Checks: the provided address to withdraw to is not zero.
        if (to == address(0)) {
            revert Errors.SablierV2__WithdrawToZeroAddress();
        }

        // Checks: count of `streamIds` matches count of `amounts`.
        uint256 streamIdsCount = streamIds.length;
        uint256 amountsCount = amounts.length;
        if (streamIdsCount != amountsCount) {
            revert Errors.SablierV2__WithdrawAllArraysNotEqual(streamIdsCount, amountsCount);
        }

        // Iterate over the provided array of stream ids and withdraw from each stream.
        uint256 streamId;
        for (uint256 i = 0; i < streamIdsCount; ) {
            streamId = streamIds[i];

            // If the `streamId` points to a stream that does not exist, we simply skip it.
            if (isEntity(streamId)) {
                // Checks: the `msg.sender` is an approved operator or the owner of the NFT (also known as the recipient
                // of the stream).
                if (!_isApprovedOrOwner(streamId, msg.sender)) {
                    revert Errors.SablierV2__Unauthorized(streamId, msg.sender);
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
