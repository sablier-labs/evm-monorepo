// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { UD60x18, toUD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "./interfaces/ISablierV2Pro.sol";
import { SablierV2 } from "./SablierV2.sol";

/// @title SablierV2Pro
/// @author Sablier Labs Ltd.
contract SablierV2Pro is
    SablierV2, // two dependencies
    ISablierV2Pro // one dependency
{
    using SafeERC20 for IERC20;

    /// INTERNAL STORAGE ///

    /// @dev Sablier V2 pro streams mapped by unsigned integers.
    mapping(uint256 => Stream) internal streams;

    /// MODIFIERS ///

    /// @dev Checks that `streamId` points to a stream that exists.
    modifier streamExists(uint256 streamId) {
        if (streams[streamId].sender == address(0)) {
            revert SablierV2__StreamNonExistent(streamId);
        }
        _;
    }

    /// @notice Checks that `msg.sender` is either the sender or the recipient of the stream.
    modifier onlySenderOrRecipient(uint256 streamId) {
        if (msg.sender != streams[streamId].sender && msg.sender != streams[streamId].recipient) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function getReturnableAmount(uint256 streamId) external view returns (uint256 returnableAmount) {
        // If the stream does not exist, return zero.
        Stream memory stream = streams[streamId];
        if (stream.sender == address(0)) {
            return 0;
        }

        unchecked {
            uint256 withdrawableAmount = getWithdrawableAmount(streamId);
            returnableAmount = stream.depositAmount - stream.withdrawnAmount - withdrawableAmount;
        }
    }

    /// @inheritdoc ISablierV2Pro
    function getStream(uint256 streamId) external view returns (Stream memory stream) {
        return streams[streamId];
    }

    /// @inheritdoc ISablierV2
    function getWithdrawableAmount(uint256 streamId) public view returns (uint256 withdrawableAmount) {
        // If the stream does not exist, return zero.
        Stream memory stream = streams[streamId];
        if (stream.sender == address(0)) {
            return 0;
        }

        // If the start time is greater than or equal to the block timestamp, return zero.
        uint256 currentTime = block.timestamp;
        if (stream.startTime >= currentTime) {
            return 0;
        }

        unchecked {
            // If the current time is greater than or equal to the stop time, return the deposit minus
            // the withdrawn amount.
            if (currentTime >= stream.stopTime) {
                return stream.depositAmount - stream.withdrawnAmount;
            }

            // In all other cases, calculate how much the recipient can withdraw.
            (UD60x18 quotient, UD60x18 amount, UD60x18 previousAmount) = getElements(stream, currentTime);
            UD60x18 streamedAmount = quotient.mul(amount);
            streamedAmount = streamedAmount.add(previousAmount);
            UD60x18 withdrawnAmount = UD60x18.wrap(stream.withdrawnAmount);
            withdrawableAmount = UD60x18.unwrap(streamedAmount.uncheckedSub(withdrawnAmount));
        }
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function cancel(uint256 streamId) external streamExists(streamId) onlySenderOrRecipient(streamId) {
        Stream memory stream = streams[streamId];

        // Checks: the stream is cancelable.
        if (!stream.cancelable) {
            revert SablierV2__StreamNonCancelable(streamId);
        }

        // Calculate the pay and the return amounts.
        uint256 withdrawAmount = getWithdrawableAmount(streamId);
        uint256 returnAmount;
        unchecked {
            returnAmount = stream.depositAmount - stream.withdrawnAmount - withdrawAmount;
        }

        // Effects: delete the stream from storage.
        delete streams[streamId];

        // Interactions: withdraw the tokens to the recipient, if any.
        if (withdrawAmount > 0) {
            stream.token.safeTransfer(stream.recipient, withdrawAmount);
        }

        // Interactions: return the tokens to the sender, if any.
        if (returnAmount > 0) {
            stream.token.safeTransfer(stream.sender, returnAmount);
        }

        // Emit an event.
        emit Cancel(streamId, stream.recipient, withdrawAmount, returnAmount);
    }

    /// Using memory instead of calldata for avoiding "Stack too deep" error.
    /// @inheritdoc ISablierV2Pro
    function create(
        address sender,
        address recipient,
        IERC20 token,
        uint256 depositAmount,
        uint256 startTime,
        uint256 stopTime,
        uint256[] memory segmentAmounts,
        uint256[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        bool cancelable
    ) external returns (uint256 streamId) {
        address from = msg.sender;

        streamId = createInternal(
            from,
            sender,
            recipient,
            token,
            depositAmount,
            startTime,
            stopTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            cancelable
        );
    }

    /// @inheritdoc ISablierV2Pro
    function createFrom(
        address from,
        address sender,
        address recipient,
        IERC20 token,
        uint256 depositAmount,
        uint256 startTime,
        uint256 stopTime,
        uint256[] memory segmentAmounts,
        uint256[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        bool cancelable
    ) external returns (uint256 streamId) {
        // Checks: the funder is not the zero address.
        if (from == address(0)) {
            revert SablierV2__FromZeroAddress();
        }

        // Checks: the caller has sufficient authorization to create this stream on behalf of `from`.
        uint256 authorization = authorizations[from][msg.sender];
        if (authorization < depositAmount) {
            revert SablierV2__InsufficientAuthorization(from, msg.sender, authorization, depositAmount);
        }

        // Effects & Interactions: create the stream.
        streamId = createInternal(
            from,
            sender,
            recipient,
            token,
            depositAmount,
            startTime,
            stopTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            cancelable
        );

        // Effects: decrease the authorization since this stream has consumed part of it.
        unchecked {
            authorizeInternal(from, msg.sender, authorization - depositAmount);
        }
    }

    /// @inheritdoc ISablierV2
    function renounce(uint256 streamId) external streamExists(streamId) {
        Stream memory stream = streams[streamId];

        // Checks: the caller is the sender of the stream.
        if (msg.sender != stream.sender) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }

        // Checks: the stream is not already non-cancelable.
        if (!stream.cancelable) {
            revert SablierV2__RenounceNonCancelableStream(streamId);
        }

        // Effects: make the stream non-cancelable.
        streams[streamId].cancelable = false;

        // Emit an event.
        emit Renounce(streamId);
    }

    /// @inheritdoc ISablierV2
    function withdraw(uint256 streamId, uint256 amount)
        external
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
    {
        // Checks: the amount cannot be zero.
        if (amount == 0) {
            revert SablierV2__WithdrawAmountZero(streamId);
        }

        // Checks: the amount cannot be greater than what can be withdrawn.
        uint256 withdrawableAmount = getWithdrawableAmount(streamId);
        if (amount > withdrawableAmount) {
            revert SablierV2__WithdrawAmountGreaterThanWithdrawableAmount(streamId, amount, withdrawableAmount);
        }

        // Effects: update the withdrawn amount.
        unchecked {
            streams[streamId].withdrawnAmount += amount;
        }

        // Load the stream in memory, we will need it later.
        Stream memory stream = streams[streamId];

        // Effects: if this stream is done, save gas by deleting it from storage.
        if (stream.depositAmount == stream.withdrawnAmount) {
            delete streams[streamId];
        }

        // Interactions: perform the ERC-20 transfer.
        stream.token.safeTransfer(stream.recipient, amount);

        // Emit an event.
        emit Withdraw(streamId, stream.recipient, amount);
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @dev See the documentation for the public functions that call this internal function.
    function createInternal(
        address from,
        address sender,
        address recipient,
        IERC20 token,
        uint256 depositAmount,
        uint256 startTime,
        uint256 stopTime,
        uint256[] memory segmentAmounts,
        uint256[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        bool cancelable
    ) internal returns (uint256 streamId) {
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

        uint256 length = checkArraysLength(segmentAmounts, segmentExponents, segmentMilestones);

        checkSegmentVariables(
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            length,
            depositAmount,
            startTime,
            stopTime
        );

        // Effects: create and store the stream.
        streamId = nextStreamId;
        streams[streamId] = Stream({
            cancelable: cancelable,
            depositAmount: depositAmount,
            recipient: recipient,
            segmentAmounts: segmentAmounts,
            segmentExponents: segmentExponents,
            segmentMilestones: segmentMilestones,
            sender: sender,
            startTime: startTime,
            stopTime: stopTime,
            token: token,
            withdrawnAmount: 0
        });

        // Effects: bump the next stream id. This cannot realistically overflow, ever.
        unchecked {
            nextStreamId = streamId + 1;
        }

        // Interactions: perform the ERC-20 transfer.
        token.safeTransferFrom(from, address(this), depositAmount);

        // Emit an event.
        emit CreateStream(
            streamId,
            sender,
            recipient,
            token,
            depositAmount,
            startTime,
            stopTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            cancelable
        );
    }

    /// HELPER FUNCTIONS ///

    /// @dev This function returns the elements for calculating withdrawable amount.
    function getElements(Stream memory stream, uint256 currentTime)
        internal
        pure
        returns (
            UD60x18 powerQuotient,
            UD60x18 amount,
            UD60x18 previousAmount
        )
    {
        uint256 length = stream.segmentAmounts.length;
        uint256 previousMilestone = stream.startTime;
        uint256 milestone;
        uint256 exponent;

        uint256 index = 0;
        while (previousMilestone < currentTime && index < length) {
            milestone = stream.segmentMilestones[index];
            exponent = stream.segmentExponents[index];
            // This order matters.
            previousAmount = previousAmount.add(amount);
            amount = UD60x18.wrap(stream.segmentAmounts[index]);

            if (milestone >= currentTime) {
                UD60x18 elapsedTime = toUD60x18(currentTime - previousMilestone);
                UD60x18 totalTime = toUD60x18(milestone - previousMilestone);
                UD60x18 quotient = elapsedTime.div(totalTime);
                powerQuotient = quotient.powu(exponent);
            }

            previousMilestone = milestone;

            unchecked {
                index += 1;
            }
        }
    }

    /// @dev This function checks arrays length:
    /// segmentAmounts.length == segmentExponents.length == segmentMilestones.length,
    /// 0 < length <= 5,
    /// @return length The length of the arrays.
    function checkArraysLength(
        uint256[] memory segmentAmounts,
        uint256[] memory segmentExponents,
        uint256[] memory segmentMilestones
    ) internal pure returns (uint256 length) {
        uint256 amountsLength = segmentAmounts.length;
        uint256 exponentsLength = segmentExponents.length;
        uint256 milestonesLength = segmentMilestones.length;

        // Checks: the length of variables that represent a segment is equal.
        if (amountsLength != exponentsLength) {
            revert SablierV2Pro__SegmentVariablesLengthIsNotEqual(amountsLength, exponentsLength, milestonesLength);
        }
        if (amountsLength != milestonesLength) {
            revert SablierV2Pro__SegmentVariablesLengthIsNotEqual(amountsLength, exponentsLength, milestonesLength);
        }

        // Checks: the variables that represent a segment lenght is bounded between zero and five.
        // it's enough to only check amountsLength because all arrays are equal to each other.
        if (amountsLength == 0) {
            revert SablierV2Pro__SegmentVariablesLengthIsOutOfBounds(amountsLength);
        }
        if (amountsLength > 5) {
            revert SablierV2Pro__SegmentVariablesLengthIsOutOfBounds(amountsLength);
        }

        // You can pass any variable length because they are all equal to each other.
        length = amountsLength;
    }

    /// @dev This function checks segment variables:
    /// amounts cumulated == `depositAmount`,
    /// 1 <= exponent <= 3,
    /// startTime <= previousMilestone < milestone <= stopTime.
    function checkSegmentVariables(
        uint256[] memory segmentAmounts,
        uint256[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        uint256 length,
        uint256 depositAmount,
        uint256 startTime,
        uint256 stopTime
    ) internal pure {
        // Checks: the start time is not greater than the first milestone.
        if (startTime > segmentMilestones[0]) {
            revert SablierV2Pro__StartTimeGreaterThanMilestone(startTime, segmentMilestones[0]);
        }

        // Checks: the last milestone is not greater than stop time.
        if (segmentMilestones[length - 1] > stopTime) {
            revert SablierV2Pro__MilestoneGreaterThanStopTime(segmentMilestones[length - 1], stopTime);
        }

        UD60x18 cumulativeAmount;
        uint256 milestone;
        uint256 previousMilestone;
        uint256 exponent;
        for (uint256 i = 0; i < length; ) {
            cumulativeAmount = cumulativeAmount.add(UD60x18.wrap(segmentAmounts[i]));

            milestone = segmentMilestones[i];

            // Checks: the previous milestone is not equal or greater than milestone.
            if (previousMilestone >= milestone) {
                revert SablierV2Pro__PreviousMilestoneIsEqualOrGreaterThanMilestone(previousMilestone, milestone);
            }
            previousMilestone = milestone;

            exponent = segmentExponents[i];

            // Checks: the exponent is not out of bounds.
            if (exponent < 1) {
                revert SablierV2Pro__SegmentExponentIsOutOfBounds(segmentExponents[i]);
            }
            if (exponent > 3) {
                revert SablierV2Pro__SegmentExponentIsOutOfBounds(segmentExponents[i]);
            }

            unchecked {
                i += 1;
            }
        }

        // Checks: amounts cumulated is equal to deposit amount.
        if (depositAmount != UD60x18.unwrap(cumulativeAmount)) {
            revert SablierV2Pro__DepositIsNotEqualToSegmentAmounts(depositAmount, cumulativeAmount);
        }
    }
}
