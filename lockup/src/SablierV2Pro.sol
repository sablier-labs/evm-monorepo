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

    /// @notice The maximum value an exponent can have is 1.
    SD59x18 public constant MAX_EXPONENT = SD59x18.wrap(10e18);

    /// @notice The maximum number of segments allowed in a stream.
    uint256 public immutable MAX_SEGMENT_COUNT;

    /// INTERNAL STORAGE ///

    /// @dev Sablier V2 pro streams mapped by unsigned integers.
    mapping(uint256 => Stream) internal streams;

    /// MODIFIERS ///

    /// @notice Checks that `msg.sender` is the recipient of the stream.
    modifier onlyRecipient(uint256 streamId) {
        if (msg.sender != streams[streamId].recipient) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
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

    /// @dev Checks that `streamId` points to a stream that exists.
    modifier streamExists(uint256 streamId) {
        if (streams[streamId].sender == address(0)) {
            revert SablierV2__StreamNonExistent(streamId);
        }
        _;
    }

    /// CONSTRUCTOR ///

    constructor(uint256 maxSegmentCount) {
        MAX_SEGMENT_COUNT = maxSegmentCount;
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function getDepositAmount(uint256 streamId) external view override returns (uint256 depositAmount) {
        depositAmount = streams[streamId].depositAmount;
    }

    /// @inheritdoc ISablierV2
    function getRecipient(uint256 streamId) public view override(ISablierV2, SablierV2) returns (address recipient) {
        recipient = streams[streamId].recipient;
    }

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

    /// @inheritdoc ISablierV2
    function getSender(uint256 streamId) public view override(ISablierV2, SablierV2) returns (address sender) {
        sender = streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2
    function getStartTime(uint256 streamId) external view override returns (uint256 startTime) {
        startTime = streams[streamId].startTime;
    }

    /// @inheritdoc ISablierV2
    function getStopTime(uint256 streamId) external view override returns (uint256 stopTime) {
        stopTime = streams[streamId].stopTime;
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
            SD59x18 currentSegmentExponent;
            SD59x18 elapsedSegmentTime;
            SD59x18 totalSegmentTime;
            uint256 previousSegmentAmounts;

            // If there's more than one segment, we have to iterate over all of them.
            uint256 segmentCount = stream.segmentAmounts.length;
            if (segmentCount > 1) {
                // Sum up the amounts found in all preceding segments. Set the sum to the negation of the first segment
                // amount such that we avoid adding an if statement in the while loop.
                uint256 currentSegmentMilestone = stream.segmentMilestones[0];
                uint256 index = 1;
                while (currentSegmentMilestone < currentTime) {
                    previousSegmentAmounts += stream.segmentAmounts[index - 1];
                    currentSegmentMilestone = stream.segmentMilestones[index];
                    index += 1;
                }

                // After the loop exits, the current segment is found at index `index - 1`, while the previous segment
                // is found at `index - 2`.
                currentSegmentAmount = SD59x18.wrap(int256(stream.segmentAmounts[index - 1]));
                currentSegmentExponent = stream.segmentExponents[index - 1];
                currentSegmentMilestone = stream.segmentMilestones[index - 1];

                // If the current segment is at an index that is >= 2, take the difference between the current segment
                // milestone and the previous segment milestone.
                if (index > 1) {
                    uint256 previousSegmentMilestone = stream.segmentMilestones[index - 2];
                    elapsedSegmentTime = toSD59x18(int256(currentTime - previousSegmentMilestone));

                    // Calculate the time between the current segment milestone and the previous segment milestone.
                    totalSegmentTime = toSD59x18(int256(currentSegmentMilestone - previousSegmentMilestone));
                }
                // If the current segment is at index 1, take the difference between the current segment milestone and
                // the start time of the stream.
                else {
                    elapsedSegmentTime = toSD59x18(int256(currentTime - stream.startTime));
                    totalSegmentTime = toSD59x18(int256(currentSegmentMilestone - stream.startTime));
                }
            }
            // Otherwise, if there's only one segment, we use the start time of the stream in the calculations.
            else {
                currentSegmentAmount = SD59x18.wrap(int256(stream.segmentAmounts[0]));
                currentSegmentExponent = stream.segmentExponents[0];
                elapsedSegmentTime = toSD59x18(int256(currentTime - stream.startTime));
                totalSegmentTime = toSD59x18(int256(stream.stopTime - stream.startTime));
            }

            // Calculate the streamed amount.
            SD59x18 quotient = elapsedSegmentTime.div(totalSegmentTime);
            SD59x18 multiplier = quotient.pow(currentSegmentExponent);
            SD59x18 proRataAmount = multiplier.mul(currentSegmentAmount);
            SD59x18 streamedAmount = SD59x18.wrap(int256(previousSegmentAmounts)).add(proRataAmount);
            SD59x18 withdrawnAmount = SD59x18.wrap(int256(stream.withdrawnAmount));
            withdrawableAmount = uint256(SD59x18.unwrap(streamedAmount.uncheckedSub(withdrawnAmount)));
        }
    }

    /// @inheritdoc ISablierV2
    function getWithdrawnAmount(uint256 streamId) external view override returns (uint256 withdrawnAmount) {
        withdrawnAmount = streams[streamId].withdrawnAmount;
    }

    /// @inheritdoc ISablierV2
    function isCancelable(uint256 streamId) public view override(ISablierV2, SablierV2) returns (bool cancelable) {
        cancelable = streams[streamId].cancelable;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2Pro
    function create(
        address funder,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        bool cancelable
    ) external returns (uint256 streamId) {
        // Checks: the funder is not the zero address.
        if (funder == address(0)) {
            revert SablierV2__FunderZeroAddress();
        }

        // If the `funder` is not the `msg.sender`, we have to perform some authorization checks.
        if (funder != msg.sender) {
            // Checks: the caller has sufficient authorization to create this stream on behalf of `funder`.
            uint256 authorization = authorizations[funder][msg.sender][token];
            if (authorization < depositAmount) {
                revert SablierV2__InsufficientAuthorization(funder, msg.sender, token, authorization, depositAmount);
            }

            // Effects: decrease the authorization since this stream consumes a part of all of it.
            unchecked {
                authorizeInternal(funder, msg.sender, token, authorization - depositAmount);
            }
        }

        // Checks, Effects and Interactions: create the stream.
        streamId = createInternal(
            funder,
            sender,
            recipient,
            depositAmount,
            token,
            startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            cancelable
        );
    }

    /// @inheritdoc ISablierV2Pro
    function createWithDuration(
        address funder,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint256[] memory segmentDeltas,
        bool cancelable
    ) external override returns (uint256 streamId) {
        uint256 startTime = block.timestamp;

        // Check that the segment delta count is not greater than the maximum segment count permitted in Sablier.
        uint256 deltaCount = segmentDeltas.length;
        if (deltaCount > MAX_SEGMENT_COUNT) {
            revert SablierV2Pro__SegmentCountOutOfBounds(deltaCount);
        }

        // Calculate the segment milestones. It is fine to use unchecked arithmetic because the `createInternal`
        // function will nonetheless check the segments.
        uint256[] memory segmentMilestones = new uint256[](deltaCount);
        unchecked {
            segmentMilestones[0] = startTime + segmentDeltas[0];
            for (uint256 i = 1; i < deltaCount; ) {
                segmentMilestones[i] = segmentMilestones[i - 1] + segmentDeltas[i];
                i += 1;
            }
        }

        // Checks, Effects and Interactions: create the stream.
        streamId = createInternal(
            funder,
            sender,
            recipient,
            depositAmount,
            token,
            startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            cancelable
        );
    }

    /// @inheritdoc ISablierV2
    function renounce(uint256 streamId) external streamExists(streamId) {
        Stream memory stream = streams[streamId];

        // Checks: the caller is the sender of the stream.
        if (msg.sender != stream.sender) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }

        // Checks: the stream is cancelable.
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
        address to = streams[streamId].recipient;
        withdrawInternal(streamId, to, amount);
    }

    /// @inheritdoc ISablierV2
    function withdrawAll(uint256[] calldata streamIds, uint256[] calldata amounts) external {
        // Checks: count of `streamIds` matches count of `amounts`.
        uint256 streamIdsCount = streamIds.length;
        uint256 amountCount = amounts.length;
        if (streamIdsCount != amountCount) {
            revert SablierV2__WithdrawAllArraysNotEqual(streamIdsCount, amountCount);
        }

        // Iterate over the provided array of stream ids and withdraw from each stream.
        address sender;
        uint256 streamId;
        for (uint256 i = 0; i < streamIdsCount; ) {
            streamId = streamIds[i];

            // If the `streamId` points to a stream that does not exist, skip it.
            sender = streams[streamId].sender;
            if (sender == address(0)) {
                // Checks: the `msg.sender` is either the sender or the recipient of the stream.
                if (msg.sender != sender && msg.sender != streams[streamId].recipient) {
                    revert SablierV2__Unauthorized(streamId, msg.sender);
                }

                // Checks, Effects and Interactions: make the withdrawal.
                withdrawInternal(streamId, streams[streamId].recipient, amounts[i]);
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
    ) external streamExists(streamId) onlyRecipient(streamId) {
        // Checks: the provided address to withdraw to is not zero.
        if (to == address(0)) {
            revert SablierV2__WithdrawZeroAddress();
        }

        // Checks, Effects and Interactions: make the withdrawal.
        withdrawInternal(streamId, to, amount);
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
        uint256 amountCount = amounts.length;
        if (streamIdsCount != amountCount) {
            revert SablierV2__WithdrawAllArraysNotEqual(streamIdsCount, amountCount);
        }

        // Iterate over the provided array of stream ids and withdraw from each stream.
        uint256 streamId;
        for (uint256 i = 0; i < streamIdsCount; ) {
            streamId = streamIds[i];

            // If the `streamId` points to a stream that does not exist, skip it.
            if (streams[streamId].sender == address(0)) {
                // Checks: the `msg.sender` is the recipient of the stream.
                if (msg.sender != streams[streamId].recipient) {
                    revert SablierV2__Unauthorized(streamId, msg.sender);
                }

                // Checks, Effects and Interactions: make the withdrawal.
                withdrawInternal(streamId, to, amounts[i]);
            }

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }
    }

    /// INTERNAL CONSTANT FUNCTIONS ///

    /// @dev Checks that the counts of segments match. The counts must be equal and less than or equal to
    /// the maximum segment count permitted in Sablier.
    /// @return segmentCount The count of the segments.
    function checkSegmentCounts(
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint256[] memory segmentMilestones
    ) internal view returns (uint256 segmentCount) {
        uint256 amountCount = segmentAmounts.length;
        uint256 exponentCount = segmentExponents.length;
        uint256 milestoneCount = segmentMilestones.length;

        // Check that the amount count is not zero.
        if (amountCount == 0) {
            revert SablierV2Pro__SegmentCountZero();
        }

        // Check that the amount count is not greater than the maximum segment count permitted in Sablier.
        if (amountCount > MAX_SEGMENT_COUNT) {
            revert SablierV2Pro__SegmentCountOutOfBounds(amountCount);
        }

        // Compare the amount count to the exponent count.
        if (amountCount != exponentCount) {
            revert SablierV2Pro__SegmentCountsNotEqual(amountCount, exponentCount, milestoneCount);
        }

        // Compare the amount count to the milestone count.
        if (amountCount != milestoneCount) {
            revert SablierV2Pro__SegmentCountsNotEqual(amountCount, exponentCount, milestoneCount);
        }

        // We can pass any count because they are all equal to each other.
        segmentCount = amountCount;
    }

    /// @dev Checks that:
    /// 1. The first milestone is greater than or equal to the start time.
    /// 2. The milestones are ordered chronologically.
    /// 3. The exponents are within the bounds permitted in Sablier.
    /// 4. The deposit amount is equal to the segment amounts summed up.
    function checkSegments(
        uint256 depositAmount,
        uint256 startTime,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        uint256 segmentCount
    ) internal pure {
        // Check that The first milestone is greater than or equal to the start time.
        if (startTime > segmentMilestones[0]) {
            revert SablierV2Pro__StartTimeGreaterThanFirstMilestone(startTime, segmentMilestones[0]);
        }

        // Define the variables needed in the for loop below.
        uint256 currentMilestone;
        SD59x18 exponent;
        uint256 previousMilestone;
        uint256 segmentAmountsSum;

        // Iterate over the amounts, the exponents and the milestones.
        uint256 index;
        for (index = 0; index < segmentCount; ) {
            // Add the current segment amount to the sum.
            segmentAmountsSum = segmentAmountsSum + segmentAmounts[index];

            // Check that the previous milestone is less than the current milestone.
            currentMilestone = segmentMilestones[index];
            if (previousMilestone >= currentMilestone) {
                revert SablierV2Pro__SegmentMilestonesNotOrdered(index, previousMilestone, currentMilestone);
            }

            // Check that the exponent is not out of bounds.
            exponent = segmentExponents[index];
            if (exponent.gt(MAX_EXPONENT)) {
                revert SablierV2Pro__SegmentExponentOutOfBounds(exponent);
            }

            // Make the current milestone the previous milestone of the next iteration.
            previousMilestone = currentMilestone;

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
    function cancelInternal(uint256 streamId) internal override onlySenderOrRecipient(streamId) {
        Stream memory stream = streams[streamId];

        // Calculate the withdraw and the return amounts.
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

    /// @dev See the documentation for the public functions that call this internal function.
    function createInternal(
        address funder,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        bool cancelable
    ) internal returns (uint256 streamId) {
        // Checks: segment counts match.
        uint256 segmentCount = checkSegmentCounts(segmentAmounts, segmentExponents, segmentMilestones);

        // Imply the stop time from the last segment milestone.
        uint256 stopTime = segmentMilestones[segmentCount - 1];

        // Checks: the common requirements for the `create` function arguments.
        checkCreateArguments(sender, recipient, depositAmount, startTime, stopTime);

        // Checks: requirements of segments variables.
        checkSegments(depositAmount, startTime, segmentAmounts, segmentExponents, segmentMilestones, segmentCount);

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
        token.safeTransferFrom(funder, address(this), depositAmount);

        // Emit an event.
        emit CreateStream(
            streamId,
            funder,
            sender,
            recipient,
            depositAmount,
            token,
            startTime,
            stopTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            cancelable
        );
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function withdrawInternal(
        uint256 streamId,
        address to,
        uint256 amount
    ) internal streamExists(streamId) {
        // Checks: the amount must not be zero.
        if (amount == 0) {
            revert SablierV2__WithdrawAmountZero(streamId);
        }

        // Checks: the amount must not be greater than the withdrawable amount.
        uint256 withdrawableAmount = getWithdrawableAmount(streamId);
        if (amount > withdrawableAmount) {
            revert SablierV2__WithdrawAmountGreaterThanWithdrawableAmount(streamId, amount, withdrawableAmount);
        }

        // Effects: update the withdrawn amount.
        unchecked {
            streams[streamId].withdrawnAmount += amount;
        }

        // Load the stream in memory, we will need it below.
        Stream memory stream = streams[streamId];

        // Effects: if this stream is done, save gas by deleting it from storage.
        if (stream.depositAmount == stream.withdrawnAmount) {
            delete streams[streamId];
        }

        // Interactions: perform the ERC-20 transfer.
        stream.token.safeTransfer(to, amount);

        // Emit an event.
        emit Withdraw(streamId, to, amount);
    }
}
