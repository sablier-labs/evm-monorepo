// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";

/// @title SablierV2
/// @author Sablier Labs Ltd.
/// @notice Abstract contract implementing common logic.
abstract contract SablierV2 is ISablierV2 {
    /// PUBLIC STORAGE ///

    /// @inheritdoc ISablierV2
    uint256 public override nextStreamId;

    /// CONSTRUCTOR ///

    constructor() {
        nextStreamId = 1;
    }

    /// CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function getRecipient(uint256 streamId) public view virtual override returns (address recipient);

    /// @inheritdoc ISablierV2
    function getSender(uint256 streamId) public view virtual override returns (address sender);

    /// @inheritdoc ISablierV2
    function isCancelable(uint256 streamId) public view virtual override returns (bool cancelable);

    /// NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function cancel(uint256 streamId) external {
        // Checks: the `streamId` points to an existing stream.
        if (getSender(streamId) == address(0)) {
            revert SablierV2__StreamNonExistent(streamId);
        }

        // Checks: the stream is cancelable.
        if (!isCancelable(streamId)) {
            revert SablierV2__StreamNonCancelable(streamId);
        }

        cancelInternal(streamId);
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
                cancelInternal(streamId);
            }

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }
    }

    /// INTERNAL CONSTANT FUNCTIONS ///

    /// @dev Checks the basic requiremenets for the `create` function.
    function checkCreateArguments(
        address funder,
        address sender,
        address recipient,
        uint256 depositAmount,
        uint256 startTime,
        uint256 stopTime
    ) internal pure {
        // Checks: the funder is not the zero address.
        if (funder == address(0)) {
            revert SablierV2__FunderZeroAddress();
        }

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

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @dev See the documentation for the public functions that call this internal function.
    function cancelInternal(uint256 streamId) internal virtual;
}
