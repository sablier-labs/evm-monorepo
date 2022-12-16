// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { Ownable } from "@prb/contracts/access/Ownable.sol";
import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { SD59x18, toSD59x18 } from "@prb/math/SD59x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { DataTypes } from "./libraries/DataTypes.sol";
import { Errors } from "./libraries/Errors.sol";
import { Events } from "./libraries/Events.sol";
import { Validations } from "./libraries/Validations.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "./interfaces/ISablierV2Pro.sol";
import { ISablierV2Recipient } from "./interfaces/ISablierV2Recipient.sol";
import { ISablierV2Sender } from "./interfaces/ISablierV2Sender.sol";
import { SablierV2 } from "./SablierV2.sol";

/// @title SablierV2Pro
/// @dev This contract implements the ISablierV2Pro interface.
contract SablierV2Pro is
    ISablierV2Pro, // one dependency
    SablierV2, // two dependencies
    ERC721("Sablier V2 Pro NFT", "SAB-V2-PRO") // six dependencies
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Pro
    uint256 public immutable override MAX_SEGMENT_COUNT;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Sablier V2 pro streams mapped by unsigned integers.
    mapping(uint256 => DataTypes.ProStream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(UD60x18 maxGlobalFee, uint256 maxSegmentCount) SablierV2(maxGlobalFee) {
        MAX_SEGMENT_COUNT = maxSegmentCount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2
    function getDepositAmount(uint256 streamId) external view override returns (uint128 depositAmount) {
        depositAmount = _streams[streamId].depositAmount;
    }

    /// @inheritdoc ISablierV2
    function getRecipient(uint256 streamId) public view override(ISablierV2, SablierV2) returns (address recipient) {
        recipient = _ownerOf(streamId);
    }

    /// @inheritdoc ISablierV2
    function getReturnableAmount(uint256 streamId) external view returns (uint128 returnableAmount) {
        // If the stream does not exist, return zero.
        if (!_streams[streamId].isEntity) {
            return 0;
        }

        unchecked {
            uint128 withdrawableAmount = getWithdrawableAmount(streamId);
            returnableAmount =
                _streams[streamId].depositAmount -
                _streams[streamId].withdrawnAmount -
                withdrawableAmount;
        }
    }

    /// @inheritdoc ISablierV2
    function getSender(uint256 streamId) external view override returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2Pro
    function getSegmentAmounts(uint256 streamId) external view override returns (uint128[] memory segmentAmounts) {
        segmentAmounts = _streams[streamId].segmentAmounts;
    }

    /// @inheritdoc ISablierV2Pro
    function getSegmentExponents(uint256 streamId) external view override returns (SD1x18[] memory segmentExponents) {
        segmentExponents = _streams[streamId].segmentExponents;
    }

    /// @inheritdoc ISablierV2Pro
    function getSegmentMilestones(uint256 streamId) external view override returns (uint40[] memory segmentMilestones) {
        segmentMilestones = _streams[streamId].segmentMilestones;
    }

    /// @inheritdoc ISablierV2
    function getStartTime(uint256 streamId) external view override returns (uint40 startTime) {
        startTime = _streams[streamId].startTime;
    }

    /// @inheritdoc ISablierV2
    function getStopTime(uint256 streamId) external view override returns (uint40 stopTime) {
        stopTime = _streams[streamId].stopTime;
    }

    /// @inheritdoc ISablierV2Pro
    function getStream(uint256 streamId) external view returns (DataTypes.ProStream memory stream) {
        return _streams[streamId];
    }

    /// @inheritdoc ISablierV2
    function getWithdrawableAmount(uint256 streamId) public view returns (uint128 withdrawableAmount) {
        // If the stream does not exist, return zero.
        if (!_streams[streamId].isEntity) {
            return 0;
        }

        // If the start time is greater than or equal to the block timestamp, return zero.
        uint40 currentTime = uint40(block.timestamp);

        if (_streams[streamId].startTime >= currentTime) {
            return 0;
        }

        unchecked {
            // If the current time is greater than or equal to the stop time, return the deposit minus
            // the withdrawn amount.
            if (currentTime >= _streams[streamId].stopTime) {
                return _streams[streamId].depositAmount - _streams[streamId].withdrawnAmount;
            }

            // Define the common variables used in the calculations below.
            SD1x18 currentSegmentExponent;
            uint128 currentSegmentAmount;
            uint128 previousSegmentAmounts;
            uint40 elapsedSegmentTime;
            uint40 totalSegmentTime;

            // If there's more than one segment, we have to iterate over all of them.
            uint256 segmentCount = _streams[streamId].segmentAmounts.length;
            if (segmentCount > 1) {
                // Sum up the amounts found in all preceding segments. Set the sum to the negation of the first segment
                // amount such that we avoid adding an if statement in the while loop.
                uint40 currentSegmentMilestone = _streams[streamId].segmentMilestones[0];
                uint256 index = 1;
                while (currentSegmentMilestone < currentTime) {
                    previousSegmentAmounts += _streams[streamId].segmentAmounts[index - 1];
                    currentSegmentMilestone = _streams[streamId].segmentMilestones[index];
                    index += 1;
                }

                // After the loop exits, the current segment is found at index `index - 1`, while the previous segment
                // is found at `index - 2`.
                currentSegmentAmount = _streams[streamId].segmentAmounts[index - 1];
                currentSegmentExponent = _streams[streamId].segmentExponents[index - 1];
                currentSegmentMilestone = _streams[streamId].segmentMilestones[index - 1];

                // If the current segment is at an index that is >= 2, take the difference between the current segment
                // milestone and the previous segment milestone.
                if (index > 1) {
                    uint40 previousSegmentMilestone = _streams[streamId].segmentMilestones[index - 2];
                    elapsedSegmentTime = currentTime - previousSegmentMilestone;

                    // Calculate the time between the current segment milestone and the previous segment milestone.
                    totalSegmentTime = currentSegmentMilestone - previousSegmentMilestone;
                }
                // If the current segment is at index 1, take the difference between the current segment milestone and
                // the start time of the stream.
                else {
                    elapsedSegmentTime = currentTime - _streams[streamId].startTime;
                    totalSegmentTime = currentSegmentMilestone - _streams[streamId].startTime;
                }
            }
            // Otherwise, if there's only one segment, we use the start time of the stream in the calculations.
            else {
                currentSegmentAmount = _streams[streamId].segmentAmounts[0];
                currentSegmentExponent = _streams[streamId].segmentExponents[0];
                elapsedSegmentTime = currentTime - _streams[streamId].startTime;
                totalSegmentTime = _streams[streamId].stopTime - _streams[streamId].startTime;
            }

            // Calculate the streamed amount.
            SD59x18 elapsedTimePercentage = toSD59x18(int256(uint256(elapsedSegmentTime))).div(
                toSD59x18(int256(uint256(totalSegmentTime)))
            );
            SD59x18 multiplier = elapsedTimePercentage.pow(SD59x18.wrap(int256(SD1x18.unwrap(currentSegmentExponent))));
            SD59x18 proRataAmount = multiplier.mul(SD59x18.wrap(int256(uint256(currentSegmentAmount))));
            SD59x18 streamedAmount = SD59x18.wrap(int256(uint256(previousSegmentAmounts))).add(proRataAmount);
            withdrawableAmount = uint128(uint256(SD59x18.unwrap(streamedAmount))) - _streams[streamId].withdrawnAmount;
        }
    }

    /// @inheritdoc ISablierV2
    function getWithdrawnAmount(uint256 streamId) external view override returns (uint128 withdrawnAmount) {
        withdrawnAmount = _streams[streamId].withdrawnAmount;
    }

    /// @inheritdoc ISablierV2
    function isCancelable(uint256 streamId) public view override(ISablierV2, SablierV2) returns (bool result) {
        result = _streams[streamId].cancelable;
    }

    /// @inheritdoc ISablierV2
    function isEntity(uint256 streamId) public view override(ISablierV2, SablierV2) returns (bool result) {
        result = _streams[streamId].isEntity;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 streamId) public view override streamExists(streamId) returns (string memory uri) {
        uri = "";
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Pro
    function create(
        address sender,
        address recipient,
        uint128 depositAmount,
        address token,
        uint40 startTime,
        uint128[] memory segmentAmounts,
        SD1x18[] memory segmentExponents,
        uint40[] memory segmentMilestones,
        bool cancelable
    ) external override returns (uint256 streamId) {
        // Checks, Effects and Interactions: create the stream.
        streamId = _create(
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
        address sender,
        address recipient,
        uint128 depositAmount,
        address token,
        uint128[] memory segmentAmounts,
        SD1x18[] memory segmentExponents,
        uint40[] memory segmentDeltas,
        bool cancelable
    ) external override returns (uint256 streamId) {
        uint40 startTime = uint40(block.timestamp);
        uint256 deltaCount = segmentDeltas.length;

        // Calculate the segment milestones. It is fine to use unchecked arithmetic because the `_create`
        // function will nonetheless check the segments.
        uint40[] memory segmentMilestones = new uint40[](deltaCount);
        unchecked {
            segmentMilestones[0] = startTime + segmentDeltas[0];
            for (uint256 i = 1; i < deltaCount; ) {
                segmentMilestones[i] = segmentMilestones[i - 1] + segmentDeltas[i];
                i += 1;
            }
        }

        // Checks, Effects and Interactions: create the stream.
        streamId = _create(
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

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierV2
    function _isApprovedOrOwner(
        uint256 streamId,
        address spender
    ) internal view override returns (bool isApprovedOrOwner) {
        address owner = _ownerOf(streamId);
        isApprovedOrOwner = (spender == owner || isApprovedForAll(owner, spender) || getApproved(streamId) == spender);
    }

    /// @inheritdoc SablierV2
    function _isCallerStreamSender(uint256 streamId) internal view override returns (bool result) {
        result = msg.sender == _streams[streamId].sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the public functions that call this internal function.
    function _burn(uint256 tokenId) internal override(ERC721, SablierV2) {
        ERC721._burn(tokenId);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _cancel(uint256 streamId) internal override onlySenderOrRecipient(streamId) {
        DataTypes.ProStream memory stream = _streams[streamId];

        // Calculate the withdraw and the return amounts.
        uint128 withdrawAmount = getWithdrawableAmount(streamId);
        uint128 returnAmount;
        unchecked {
            returnAmount = stream.depositAmount - stream.withdrawnAmount - withdrawAmount;
        }

        // Load the sender and the recipient in memory, we will need them below.
        address sender = _streams[streamId].sender;
        address recipient = getRecipient(streamId);

        // Effects: delete the stream from storage.
        delete _streams[streamId];

        // Interactions: withdraw the tokens to the recipient, if any.
        if (withdrawAmount > 0) {
            IERC20(stream.token).safeTransfer({ to: recipient, amount: withdrawAmount });
        }

        // Interactions: return the tokens to the sender, if any.
        if (returnAmount > 0) {
            IERC20(stream.token).safeTransfer({ to: sender, amount: returnAmount });
        }

        // Interactions: if the `msg.sender` is the sender and the recipient is a contract, try to invoke the cancel
        // hook on the recipient without reverting if the hook is not implemented, and without bubbling up any
        // potential revert.
        if (msg.sender == sender) {
            if (recipient.code.length > 0) {
                try
                    ISablierV2Recipient(recipient).onStreamCanceled({
                        streamId: streamId,
                        caller: msg.sender,
                        withdrawAmount: withdrawAmount,
                        returnAmount: returnAmount
                    })
                {} catch {}
            }
        }
        // Interactions: if the `msg.sender` is the recipient and the sender is a contract, try to invoke the cancel
        // hook on the sender without reverting if the hook is not implemented, and also without bubbling up any
        // potential revert.
        else {
            if (sender.code.length > 0) {
                try
                    ISablierV2Sender(sender).onStreamCanceled({
                        streamId: streamId,
                        caller: msg.sender,
                        withdrawAmount: withdrawAmount,
                        returnAmount: returnAmount
                    })
                {} catch {}
            }
        }

        // Emit an event.
        emit Events.Cancel(streamId, sender, recipient, withdrawAmount, returnAmount);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _create(
        address sender,
        address recipient,
        uint128 depositAmount,
        address token,
        uint40 startTime,
        uint128[] memory segmentAmounts,
        SD1x18[] memory segmentExponents,
        uint40[] memory segmentMilestones,
        bool cancelable
    ) internal returns (uint256 streamId) {
        // Checks: the arguments of the function.
        Validations.checkCreateProArgs(
            depositAmount,
            startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            MAX_SEGMENT_COUNT
        );

        // We can use any count because they are all equal to each other.
        uint256 segmentCount = segmentAmounts.length;
        uint40 stopTime;
        unchecked {
            stopTime = segmentMilestones[segmentCount - 1];
        }

        // Effects: create the stream.
        streamId = nextStreamId;
        _streams[streamId] = DataTypes.ProStream({
            cancelable: cancelable,
            depositAmount: depositAmount,
            isEntity: true,
            segmentAmounts: segmentAmounts,
            segmentExponents: segmentExponents,
            segmentMilestones: segmentMilestones,
            sender: sender,
            startTime: startTime,
            stopTime: stopTime,
            token: token,
            withdrawnAmount: 0
        });

        // Effects: mint the NFT for the recipient by setting the stream id as the token id.
        _mint({ to: recipient, tokenId: streamId });

        // Effects: bump the next stream id. This cannot realistically overflow, ever.
        unchecked {
            nextStreamId = streamId + 1;
        }

        // Interactions: safely perform the ERC-20 transfer.
        IERC20(token).safeTransferFrom({ from: msg.sender, to: address(this), amount: depositAmount });

        // Emit an event.
        emit Events.CreateProStream({
            streamId: streamId,
            funder: msg.sender,
            sender: sender,
            recipient: recipient,
            depositAmount: depositAmount,
            token: token,
            startTime: startTime,
            stopTime: stopTime,
            segmentAmounts: segmentAmounts,
            segmentExponents: segmentExponents,
            segmentMilestones: segmentMilestones,
            cancelable: cancelable
        });
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _renounce(uint256 streamId) internal override {
        // Effects: make the stream non-cancelable.
        _streams[streamId].cancelable = false;

        // Emit an event.
        emit Events.Renounce(streamId);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal override {
        // Checks: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2__WithdrawAmountZero(streamId);
        }

        // Checks: the amount is not greater than what can be withdrawn.
        uint128 withdrawableAmount = getWithdrawableAmount(streamId);
        if (amount > withdrawableAmount) {
            revert Errors.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount(streamId, amount, withdrawableAmount);
        }

        // Effects: update the withdrawn amount.
        unchecked {
            _streams[streamId].withdrawnAmount += amount;
        }

        // Load the stream in memory, we will need it below.
        DataTypes.ProStream memory stream = _streams[streamId];
        address recipient = getRecipient(streamId);

        // Effects: if this stream is done, delete it from storage.
        if (stream.depositAmount == stream.withdrawnAmount) {
            delete _streams[streamId];
        }

        // Interactions: safely perform the ERC-20 transfer.
        IERC20(stream.token).safeTransfer(to, amount);

        // Interactions: if the `msg.sender` is not the recipient and the recipient is a contract, try to invoke the
        // withdraw hook on it without reverting if the hook is not implemented, and also without bubbling up
        // any potential revert.
        if (msg.sender != recipient && recipient.code.length > 0) {
            try
                ISablierV2Recipient(recipient).onStreamWithdrawn({
                    streamId: streamId,
                    caller: msg.sender,
                    withdrawAmount: amount
                })
            {} catch {}
        }

        // Emit an event.
        emit Events.Withdraw(streamId, to, amount);
    }
}
