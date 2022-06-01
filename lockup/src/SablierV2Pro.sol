// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { SCALE, SD59x18, toSD59x18, ZERO } from "@prb/math/SD59x18.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "./interfaces/ISablierV2Pro.sol";
import { SablierV2 } from "./SablierV2.sol";

/// @title SablierV2Pro
/// @author Sablier Labs Ltd.
contract SablierV2Pro is
    ISablierV2Pro, // one dependency
    SablierV2 // two dependencies
{
    using SafeERC20 for IERC20;

    /// CONSTANTS ///

    /// @notice The maximum number of segments allowed in a stream.
    SD59x18 public constant MAX_EXPONENT = SD59x18.wrap(10e18);

    /// @notice The maximum number of segments allowed in a stream.
    uint256 public constant MAX_SEGMENT_ARRAY_LENGTH = 200;

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

            // Define the common variables used in the calculations below.
            SD59x18 currentSegmentAmount;
            uint256 currentSegmentMilestone = stream.startTime;
            SD59x18 elapsedSegmentTime;
            SD59x18 exponent;
            SD59x18 totalSegmentTime;
            uint256 sum;

            // If there's more than one segment, we have to iterate over all of them
            uint256 length = stream.segmentMilestones.length;
            if (length > 1) {
                // Sum up the amounts found in preceding segments.
                uint256 index = 0;
                while (currentSegmentMilestone < currentTime) {
                    currentSegmentMilestone = stream.segmentMilestones[index];
                    sum += stream.segmentAmounts[index];
                    index += 1;
                }

                // After the loop exits, the current segment is found at index `index - 1`, and the previous segment is
                // found at index `index - 2`.
                currentSegmentAmount = SD59x18.wrap(int256(stream.segmentAmounts[index - 1]));
                currentSegmentMilestone = stream.segmentMilestones[index - 1];
                exponent = stream.segmentExponents[index - 1];

                // If the current segment is at an index of greater than or equal to 2, take the difference between
                // the current segment milestone and the previous segment milestone.
                if (index > 1) {
                    uint256 previousSegmentMilestone = stream.segmentMilestones[index - 2];
                    elapsedSegmentTime = toSD59x18(int256(currentTime - previousSegmentMilestone));

                    // Calculate the total time between the current segment milestone and the previous segment
                    // milestone.
                    totalSegmentTime = toSD59x18(int256(currentSegmentMilestone - previousSegmentMilestone));
                }
                // If the current segment is at index 1, take the difference between the current segment milestone and
                // the start time of the stream.
                else {
                    elapsedSegmentTime = toSD59x18(int256(currentTime - stream.startTime));
                    totalSegmentTime = toSD59x18(int256(currentSegmentMilestone - stream.startTime));
                }
            }
            // If there's only segment, consider the start time of stream the first segment milestone, and the stop time
            // of the stream as the last segment milestone.
            else {
                exponent = stream.segmentExponents[0];
                currentSegmentAmount = SD59x18.wrap(int256(stream.segmentAmounts[0]));
                elapsedSegmentTime = toSD59x18(int256(currentTime - currentSegmentMilestone));
                totalSegmentTime = toSD59x18(int256(stream.stopTime - stream.startTime));
            }

            // Calculate the streamed amount.
            SD59x18 quotient = elapsedSegmentTime.div(totalSegmentTime);
            SD59x18 multiplier = quotient.pow(exponent);
            SD59x18 proRataAmount = multiplier.mul(currentSegmentAmount);
            SD59x18 streamedAmount = SD59x18.wrap(int256(sum)).add(proRataAmount);
            SD59x18 withdrawnAmount = SD59x18.wrap(int256(stream.withdrawnAmount));
            withdrawableAmount = uint256(SD59x18.unwrap(streamedAmount.uncheckedSub(withdrawnAmount)));
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

    /// @inheritdoc ISablierV2Pro
    function create(
        address sender,
        address recipient,
        IERC20 token,
        uint256 depositAmount,
        uint256 startTime,
        uint256 stopTime,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
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
        SD59x18[] memory segmentExponents,
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

    /// INTERNAL CONSTANT FUNCTIONS ///

    /// @dev Checks that the segment arrays lengths match. The lengths must be equal and less than or equal to
    /// the maximum array length permitted in Sablier.
    /// @return length The length of the arrays.
    function checkSegmentArraysLength(
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint256[] memory segmentMilestones
    ) internal pure returns (uint256 length) {
        uint256 amountsLength = segmentAmounts.length;
        uint256 exponentsLength = segmentExponents.length;
        uint256 milestonesLength = segmentMilestones.length;

        // Compare the amounts array length to the exponents array length.
        if (amountsLength != exponentsLength) {
            revert SablierV2Pro__SegmentArraysLengthsUnequal(amountsLength, exponentsLength, milestonesLength);
        }

        // Compare the amounts array length to the milestones array length.
        if (amountsLength != milestonesLength) {
            revert SablierV2Pro__SegmentArraysLengthsUnequal(amountsLength, exponentsLength, milestonesLength);
        }

        // Check that the amounts array length is not zero.
        if (amountsLength == 0) {
            revert SablierV2Pro__SegmentArraysLengthZero();
        }

        // Check that the amounts array length is not greater than the maximum array length permitted by Sablier.
        if (amountsLength > MAX_SEGMENT_ARRAY_LENGTH) {
            revert SablierV2Pro__SegmentArraysLengthOutOfBounds(amountsLength);
        }

        // We can pass any variable length because they are all equal to each other.
        length = amountsLength;
    }

    /// @dev Checks that:
    /// 1. The milestones are bounded by the start time and the stop time.
    /// 2. The milestones are ordered chronologically.
    /// 3. The exponents are within the bounds permitted by Sablier.
    /// 4. The deposit amount is equal to the segment amounts summed up.
    function checkSegmentVariables(
        uint256 depositAmount,
        uint256 startTime,
        uint256 stopTime,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        uint256 length
    ) internal pure {
        // Check that the start time is not greater than the first milestone.
        if (startTime > segmentMilestones[0]) {
            revert SablierV2Pro__StartTimeGreaterThanFirstMilestone(startTime, segmentMilestones[0]);
        }

        // Check that the last milestone is not greater than the stop time.
        if (segmentMilestones[length - 1] > stopTime) {
            revert SablierV2Pro__LastMilestoneGreaterThanStopTime(segmentMilestones[length - 1], stopTime);
        }

        // Define the variables needed in the for loop below.
        uint256 currentMilestone;
        SD59x18 exponent;
        uint256 previousMilestone;
        uint256 segmentAmountsSum;

        // Iterate over the amounts, the milestones and the exponents.
        uint256 index;
        for (index = 0; index < length; ) {
            // Add the current segment amount to the sum.
            segmentAmountsSum = segmentAmountsSum + segmentAmounts[index];

            // Check that the previous milestone is not equal or greater than the current milestone.
            currentMilestone = segmentMilestones[index];
            if (previousMilestone >= currentMilestone) {
                revert SablierV2Pro__UnorderedMilestones(index, previousMilestone, currentMilestone);
            }

            // Set the current milestone to be the previous milestone of the next iteration.
            previousMilestone = currentMilestone;

            // Check that the exponent is not out of bounds.
            exponent = segmentExponents[index];
            if (exponent.gt(MAX_EXPONENT)) {
                revert SablierV2Pro__SegmentExponentOutOfBounds(exponent);
            }

            // Increment the for loop iterator.
            unchecked {
                index += 1;
            }
        }

        // Check that the deposit amount is equal to the segment amounts sum.
        if (depositAmount != segmentAmountsSum) {
            revert SablierV2Pro__DepositAmountNotEqualToSegmentAmountsSum(depositAmount, segmentAmountsSum);
        }
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
        SD59x18[] memory segmentExponents,
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

        // Checks: segments arrays lengths match.
        uint256 length = checkSegmentArraysLength(segmentAmounts, segmentExponents, segmentMilestones);

        // Checks: soundness of segments variables.
        checkSegmentVariables(
            depositAmount,
            startTime,
            stopTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            length
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
}
