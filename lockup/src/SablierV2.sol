// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { ISablierV2 } from "./interfaces/ISablierV2.sol";

/// @title SablierV2
/// @author Sablier Labs Ltd.
/// @notice Abstract contract implementing common logic.
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
        if (msg.sender != getSender(streamId) && !_isApprovedOrOwner(msg.sender, streamId)) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /// @dev Checks that `streamId` points to a stream that exists.
    modifier streamExists(uint256 streamId) {
        if (getSender(streamId) == address(0)) {
            revert SablierV2__StreamNonExistent(streamId);
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
    function getSender(uint256 streamId) public view virtual override returns (address sender);

    /// @inheritdoc ISablierV2
    function isCancelable(uint256 streamId) public view virtual override returns (bool cancelable);

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2
    function cancel(uint256 streamId) external streamExists(streamId) {
        // Checks: the stream is cancelable.
        if (!isCancelable(streamId)) {
            revert SablierV2__StreamNonCancelable(streamId);
        }

        _cancel(streamId);
    }

    /// @inheritdoc ISablierV2
    function cancelAll(uint256[] calldata streamIds) external {
        // Iterate over the provided array of stream ids and cancel each stream that exists and is cancelable.
        uint256 count = streamIds.length;
        uint256 streamId;
        for (uint256 i = 0; i < count; ) {
            streamId = streamIds[i];

            // Cancel the stream only if the `streamId` points to a stream that exists and is cancelable.
            if (getSender(streamId) != address(0) && isCancelable(streamId)) {
                _cancel(streamId);
            }

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }
    }

    /// @inheritdoc ISablierV2
    function renounce(uint256 streamId) external streamExists(streamId) {
        // Checks: the caller is the sender of the stream.
        if (msg.sender != getSender(streamId)) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }

        // Checks: the stream is cancelable.
        if (!isCancelable(streamId)) {
            revert SablierV2__RenounceNonCancelableStream(streamId);
        }

        _renounce(streamId);
    }

    /// @inheritdoc ISablierV2
    function withdraw(uint256 streamId, uint256 amount)
        external
        streamExists(streamId)
        isAuthorizedForStream(streamId)
    {
        address recipient = getRecipient(streamId);
        _withdraw(streamId, recipient, amount);
    }

    /// @inheritdoc ISablierV2
    function withdrawAll(uint256[] calldata streamIds, uint256[] calldata amounts) external {
        // Checks: count of `streamIds` matches count of `amounts`.
        uint256 streamIdsCount = streamIds.length;
        uint256 amountsCount = amounts.length;
        if (streamIdsCount != amountsCount) {
            revert SablierV2__WithdrawAllArraysNotEqual(streamIdsCount, amountsCount);
        }

        // Iterate over the provided array of stream ids and withdraw from each stream.
        address recipient;
        address sender;
        uint256 streamId;
        for (uint256 i = 0; i < streamIdsCount; ) {
            streamId = streamIds[i];

            // If the `streamId` points to a stream that does not exist, skip it.
            recipient = getRecipient(streamId);
            sender = getSender(streamId);
            if (sender != address(0)) {
                // Checks: the `msg.sender` is the sender or the stream, an approved operator, or the owner of the NFT
                // (a.k.a. the recipient of the stream).
                if (msg.sender != sender && !_isApprovedOrOwner(msg.sender, streamId)) {
                    revert SablierV2__Unauthorized(streamId, msg.sender);
                }

                // Effects and Interactions: withdraw from the stream.
                _withdraw(streamId, recipient, amounts[i]);
            }

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }
    }

    /// @inheritdoc ISablierV2
    function withdrawAllTo(
        uint256[] calldata streamIds,
        address to,
        uint256[] calldata amounts
    ) external {
        // Checks: the provided address to withdraw to is not zero.
        if (to == address(0)) {
            revert SablierV2__WithdrawZeroAddress();
        }

        // Checks: count of `streamIds` matches `amounts`.
        uint256 streamIdsCount = streamIds.length;
        uint256 amountsCount = amounts.length;
        if (streamIdsCount != amountsCount) {
            revert SablierV2__WithdrawAllArraysNotEqual(streamIdsCount, amountsCount);
        }

        // Iterate over the provided array of stream ids and withdraw from each stream.
        uint256 streamId;
        for (uint256 i = 0; i < streamIdsCount; ) {
            streamId = streamIds[i];

            // If the `streamId` points to a stream that does not exist, skip it.
            if (getSender(streamId) != address(0)) {
                // Checks: the `msg.sender` is either an approved operator or the owner of the NFT (a.k.a. the recipient
                // of the stream).
                if (!_isApprovedOrOwner(msg.sender, streamId)) {
                    revert SablierV2__Unauthorized(streamId, msg.sender);
                }

                // Effects and Interactions: withdraw from the stream.
                _withdraw(streamId, to, amounts[i]);
            }

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }
    }

    /// @inheritdoc ISablierV2
    function withdrawTo(
        uint256 streamId,
        address to,
        uint256 amount
    ) external streamExists(streamId) {
        // Checks: the provided address to withdraw to is not zero.
        if (to == address(0)) {
            revert SablierV2__WithdrawZeroAddress();
        }

        // Checks: the `msg.sender` is either an approved operator or the owner of the NFT (a.k.a. the recipient
        // of the stream).
        if (!_isApprovedOrOwner(msg.sender, streamId)) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }
        _withdraw(streamId, to, amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the basic requirements for the `create` function.
    function _checkCreateArguments(
        address sender,
        address recipient,
        uint256 depositAmount,
        uint64 startTime,
        uint64 stopTime
    ) internal pure {
        // Checks: the sender is not the zero address.
        if (sender == address(0)) {
            revert SablierV2__SenderZeroAddress();
        }

        // Checks: the recipient is not the zero address.
        if (recipient == address(0)) {
            revert SablierV2__RecipientZeroAddress();
        }

        // Checks: the deposit amount is not zero.
        if (depositAmount == 0) {
            revert SablierV2__DepositAmountZero();
        }

        // Checks: the start time is not greater than the stop time.
        if (startTime > stopTime) {
            revert SablierV2__StartTimeGreaterThanStopTime(startTime, stopTime);
        }
    }

    /// @dev Checks whether the spender is authorized to interact with the stream.
    /// @param spender The spender to make the query for.
    /// @param streamId The id of the stream to make the query for.
    function _isApprovedOrOwner(address spender, uint256 streamId) internal view virtual returns (bool approvedOrOwner);

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the public functions that call this internal function.
    function _cancel(uint256 streamId) internal virtual;

    /// @dev See the documentation for the public functions that call this internal function.
    function _renounce(uint256 streamId) internal virtual;

    /// @dev See the documentation for the public functions that call this internal function.
    function _withdraw(
        uint256 streamId,
        address to,
        uint256 amount
    ) internal virtual;
}
