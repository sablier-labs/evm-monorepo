// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Amounts, CreateAmounts, CreateWithMilestonesArgs, ProStream, Segment } from "./types/Structs.sol";
import { Errors } from "./libraries/Errors.sol";
import { Events } from "./libraries/Events.sol";
import { Helpers } from "./libraries/Helpers.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";
import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Pro } from "./interfaces/ISablierV2Pro.sol";
import { ISablierV2Recipient } from "./hooks/ISablierV2Recipient.sol";
import { ISablierV2Sender } from "./hooks/ISablierV2Sender.sol";
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
    mapping(uint256 => ProStream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        ISablierV2Comptroller initialComptroller,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) SablierV2(initialComptroller, maxFee) {
        MAX_SEGMENT_COUNT = maxSegmentCount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2
    function getDepositAmount(uint256 streamId) external view override returns (uint128 depositAmount) {
        depositAmount = _streams[streamId].amounts.deposit;
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
                _streams[streamId].amounts.deposit -
                _streams[streamId].amounts.withdrawn -
                withdrawableAmount;
        }
    }

    /// @inheritdoc ISablierV2Pro
    function getSegments(uint256 streamId) external view override returns (Segment[] memory segments) {
        segments = _streams[streamId].segments;
    }

    /// @inheritdoc ISablierV2
    function getSender(uint256 streamId) external view override returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2
    function getStartTime(uint256 streamId) external view override returns (uint40 startTime) {
        startTime = _streams[streamId].startTime;
    }

    /// @inheritdoc ISablierV2
    function getStopTime(uint256 streamId) external view override returns (uint40 stopTime) {
        unchecked {
            uint256 segmentCount = _streams[streamId].segments.length;
            if (segmentCount > 0) {
                stopTime = _streams[streamId].segments[segmentCount - 1].milestone;
            }
        }
    }

    /// @inheritdoc ISablierV2Pro
    function getStream(uint256 streamId) external view returns (ProStream memory stream) {
        stream = _streams[streamId];
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
            uint256 segmentCount = _streams[streamId].segments.length;
            uint40 stopTime = _streams[streamId].segments[segmentCount - 1].milestone;

            // If the current time is greater than or equal to the stop time, we return the deposit minus
            // the withdrawn amount.
            if (currentTime >= stopTime) {
                return _streams[streamId].amounts.deposit - _streams[streamId].amounts.withdrawn;
            }

            if (segmentCount > 1) {
                // If there's more than one segment, we have to iterate over all of them.
                withdrawableAmount = _calculateWithdrawableAmountForMultipleSegments(streamId);
            } else {
                // Otherwise, there is only one segment, and the calculation is simple.
                withdrawableAmount = _calculateWithdrawableAmountForOneSegment(streamId);
            }
        }
    }

    /// @inheritdoc ISablierV2
    function getWithdrawnAmount(uint256 streamId) external view override returns (uint128 withdrawnAmount) {
        withdrawnAmount = _streams[streamId].amounts.withdrawn;
    }

    /// @inheritdoc ISablierV2
    function isCancelable(uint256 streamId) public view override(ISablierV2, SablierV2) returns (bool result) {
        result = _streams[streamId].isCancelable;
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
    function createWithDeltas(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        Segment[] memory segments,
        address operator,
        UD60x18 operatorFee,
        address token,
        bool cancelable,
        uint40[] calldata deltas
    ) external override returns (uint256 streamId) {
        // Checks: check the deltas and adjust the segments accordingly.
        Helpers.checkDeltasAndAdjustSegments(segments, deltas);

        // Checks: check the fees and calculate the fee amounts.
        CreateAmounts memory amounts = Helpers.checkAndCalculateFees(
            comptroller,
            token,
            grossDepositAmount,
            operatorFee,
            MAX_FEE
        );

        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithMilestones(
            CreateWithMilestonesArgs({
                amounts: amounts,
                cancelable: cancelable,
                operator: operator,
                recipient: recipient,
                segments: segments,
                sender: sender,
                token: token,
                startTime: uint40(block.timestamp)
            })
        );
    }

    /// @inheritdoc ISablierV2Pro
    function createWithMilestones(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        Segment[] calldata segments,
        address operator,
        UD60x18 operatorFee,
        address token,
        bool cancelable,
        uint40 startTime
    ) external returns (uint256 streamId) {
        // Checks: check the fees and calculate the fee amounts.
        CreateAmounts memory amounts = Helpers.checkAndCalculateFees(
            comptroller,
            token,
            grossDepositAmount,
            operatorFee,
            MAX_FEE
        );

        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithMilestones(
            CreateWithMilestonesArgs({
                amounts: amounts,
                cancelable: cancelable,
                operator: operator,
                recipient: recipient,
                segments: segments,
                sender: sender,
                token: token,
                startTime: startTime
            })
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
        ProStream memory stream = _streams[streamId];

        // Calculate the withdraw and the return amounts.
        uint128 recipientAmount = getWithdrawableAmount(streamId);
        uint128 senderAmount;
        unchecked {
            senderAmount = stream.amounts.deposit - stream.amounts.withdrawn - recipientAmount;
        }

        // Load the sender and the recipient in memory, we will need them below.
        address sender = _streams[streamId].sender;
        address recipient = _ownerOf(streamId);

        // Effects: delete the stream from storage.
        delete _streams[streamId];

        // Interactions: withdraw the tokens to the recipient, if any.
        if (recipientAmount > 0) {
            IERC20(stream.token).safeTransfer({ to: recipient, amount: recipientAmount });
        }

        // Interactions: return the tokens to the sender, if any.
        if (senderAmount > 0) {
            IERC20(stream.token).safeTransfer({ to: sender, amount: senderAmount });
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
                        recipientAmount: recipientAmount,
                        senderAmount: senderAmount
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
                        recipientAmount: recipientAmount,
                        senderAmount: senderAmount
                    })
                {} catch {}
            }
        }

        // Emit an event.
        emit Events.Cancel(streamId, sender, recipient, senderAmount, recipientAmount);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _createWithMilestones(CreateWithMilestonesArgs memory args) internal returns (uint256 streamId) {
        // Checks: validate the arguments.
        Helpers.checkCreateProArgs(args.amounts.netDeposit, args.segments, MAX_SEGMENT_COUNT, args.startTime);

        // Load the stream id.
        streamId = nextStreamId;

        // Effects: create the stream.
        ProStream storage stream = _streams[streamId];
        stream.amounts = Amounts({ deposit: args.amounts.netDeposit, withdrawn: 0 });
        stream.isCancelable = args.cancelable;
        stream.isEntity = true;
        stream.sender = args.sender;
        stream.startTime = args.startTime;
        stream.token = args.token;

        unchecked {
            // Effects: store the segments. Copying an array from memory to storage is not currently supported, so we
            // have to do it manually. See https://github.com/ethereum/solidity/issues/12783
            uint256 segmentCount = args.segments.length;
            for (uint256 i = 0; i < segmentCount; ++i) {
                stream.segments.push(args.segments[i]);
            }

            // Effects: bump the next stream id and record the protocol fee.
            // We're using unchecked arithmetic here because theses calculations cannot realistically overflow, ever.
            nextStreamId = streamId + 1;
            _protocolRevenues[args.token] += args.amounts.protocolFee;
        }

        // Effects: mint the NFT for the recipient.
        _mint({ to: args.recipient, tokenId: streamId });

        // Interactions: perform the ERC-20 transfer to deposit the gross amount of tokens.
        IERC20(args.token).safeTransferFrom({ from: msg.sender, to: address(this), amount: args.amounts.netDeposit });

        // Interactions: perform the ERC-20 transfer to pay the operator fee, if not zero.
        if (args.amounts.operatorFee > 0) {
            IERC20(args.token).safeTransferFrom({
                from: msg.sender,
                to: args.operator,
                amount: args.amounts.operatorFee
            });
        }

        // Emit an event.
        emit Events.CreateProStream({
            streamId: streamId,
            funder: msg.sender,
            sender: args.sender,
            recipient: args.recipient,
            depositAmount: args.amounts.netDeposit,
            segments: args.segments,
            protocolFeeAmount: args.amounts.protocolFee,
            operator: args.operator,
            operatorFeeAmount: args.amounts.operatorFee,
            token: args.token,
            cancelable: args.cancelable,
            startTime: args.startTime
        });
    }

    /// @dev Calculates the withdrawable amount for a stream with multiple segments.
    function _calculateWithdrawableAmountForMultipleSegments(
        uint256 streamId
    ) internal view returns (uint128 withdrawableAmount) {
        unchecked {
            uint40 currentTime = uint40(block.timestamp);

            // Sum up the amounts found in all preceding segments. Set the sum to the negation of the first segment
            // amount such that we avoid adding an if statement in the while loop.
            uint128 previousSegmentAmounts;
            uint40 currentSegmentMilestone = _streams[streamId].segments[0].milestone;
            uint256 index = 1;
            while (currentSegmentMilestone < currentTime) {
                previousSegmentAmounts += _streams[streamId].segments[index - 1].amount;
                currentSegmentMilestone = _streams[streamId].segments[index].milestone;
                index += 1;
            }

            // After the loop exits, the current segment is found at index `index - 1`, while the previous segment
            // is found at `index - 2`.
            uint128 currentSegmentAmount = _streams[streamId].segments[index - 1].amount;
            SD1x18 currentSegmentExponent = _streams[streamId].segments[index - 1].exponent;
            currentSegmentMilestone = _streams[streamId].segments[index - 1].milestone;

            // Define the time variables.
            uint40 elapsedSegmentTime;
            uint40 totalSegmentTime;

            // If the current segment is at an index that is >= 2, we take the difference between the current
            // segment milestone and the previous segment milestone.
            if (index > 1) {
                uint40 previousSegmentMilestone = _streams[streamId].segments[index - 2].milestone;
                elapsedSegmentTime = currentTime - previousSegmentMilestone;

                // Calculate the time between the current segment milestone and the previous segment milestone.
                totalSegmentTime = currentSegmentMilestone - previousSegmentMilestone;
            }
            // If the current segment is at index 1, we take the difference between the current segment milestone
            // and the start time of the stream.
            else {
                elapsedSegmentTime = currentTime - _streams[streamId].startTime;
                totalSegmentTime = currentSegmentMilestone - _streams[streamId].startTime;
            }

            // Calculate the streamed amount.
            SD59x18 elapsedTimePercentage = SD59x18.wrap(int256(uint256(elapsedSegmentTime))).div(
                SD59x18.wrap(int256(uint256(totalSegmentTime)))
            );
            SD59x18 multiplier = elapsedTimePercentage.pow(SD59x18.wrap(int256(SD1x18.unwrap(currentSegmentExponent))));
            SD59x18 proRataAmount = multiplier.mul(SD59x18.wrap(int256(uint256(currentSegmentAmount))));
            uint128 streamedAmount = previousSegmentAmounts + uint128(uint256(SD59x18.unwrap(proRataAmount)));
            withdrawableAmount = streamedAmount - _streams[streamId].amounts.withdrawn;
        }
    }

    /// @dev Calculates the withdrawable amount for a stream with one segment.
    function _calculateWithdrawableAmountForOneSegment(
        uint256 streamId
    ) internal view returns (uint128 withdrawableAmount) {
        unchecked {
            uint128 currentSegmentAmount = _streams[streamId].segments[0].amount;
            SD1x18 currentSegmentExponent = _streams[streamId].segments[0].exponent;
            SD59x18 elapsedSegmentTime = SD59x18.wrap(
                int256(uint256(uint40(block.timestamp) - _streams[streamId].startTime))
            );
            uint40 stopTime = _streams[streamId].segments[0].milestone;
            SD59x18 totalSegmentTime = SD59x18.wrap(int256(uint256(stopTime - _streams[streamId].startTime)));

            // Calculate the streamed amount.
            SD59x18 elapsedTimePercentage = elapsedSegmentTime.div(totalSegmentTime);
            SD59x18 multiplier = elapsedTimePercentage.pow(SD59x18.wrap(int256(SD1x18.unwrap(currentSegmentExponent))));
            SD59x18 streamedAmount = multiplier.mul(SD59x18.wrap(int256(uint256(currentSegmentAmount))));
            withdrawableAmount =
                uint128(uint256(SD59x18.unwrap(streamedAmount))) -
                _streams[streamId].amounts.withdrawn;
        }
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _renounce(uint256 streamId) internal override {
        // Effects: make the stream non-cancelable.
        _streams[streamId].isCancelable = false;

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
            _streams[streamId].amounts.withdrawn += amount;
        }

        // Load the stream in memory, we will need it below.
        ProStream memory stream = _streams[streamId];
        address recipient = _ownerOf(streamId);

        // Assert that the withdrawn amount cannot get greater than the deposit amount.
        assert(stream.amounts.deposit >= stream.amounts.withdrawn);

        // Effects: if this stream is done, delete it from storage.
        if (stream.amounts.deposit == stream.amounts.withdrawn) {
            delete _streams[streamId];
        }

        // Interactions: perform the ERC-20 transfer.
        IERC20(stream.token).safeTransfer({ to: to, amount: amount });

        // Interactions: if the `msg.sender` is not the recipient and the recipient is a contract, try to invoke the
        // withdraw hook on it without reverting if the hook is not implemented, and also without bubbling up
        // any potential revert.
        if (msg.sender != recipient && recipient.code.length > 0) {
            try
                ISablierV2Recipient(recipient).onStreamWithdrawn({
                    streamId: streamId,
                    caller: msg.sender,
                    amount: amount
                })
            {} catch {}
        }

        // Emit an event.
        emit Events.Withdraw(streamId, to, amount);
    }
}
