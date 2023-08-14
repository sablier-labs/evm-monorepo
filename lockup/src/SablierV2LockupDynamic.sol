// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/src/casting/Uint128.sol";
import { PRBMathCastingUint40 as CastingUint40 } from "@prb/math/src/casting/Uint40.sol";
import { SD59x18 } from "@prb/math/src/SD59x18.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { SablierV2Lockup } from "./abstracts/SablierV2Lockup.sol";
import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Lockup } from "./interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupDynamic } from "./interfaces/ISablierV2LockupDynamic.sol";
import { ISablierV2LockupRecipient } from "./interfaces/hooks/ISablierV2LockupRecipient.sol";
import { ISablierV2LockupSender } from "./interfaces/hooks/ISablierV2LockupSender.sol";
import { ISablierV2NFTDescriptor } from "./interfaces/ISablierV2NFTDescriptor.sol";
import { Errors } from "./libraries/Errors.sol";
import { Helpers } from "./libraries/Helpers.sol";
import { Lockup, LockupDynamic } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ██╗   ██╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██║   ██║╚════██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    ██║   ██║ █████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ╚██╗ ██╔╝██╔═══╝
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║     ╚████╔╝ ███████╗
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚══════╝

██╗      ██████╗  ██████╗██╗  ██╗██╗   ██╗██████╗     ██████╗ ██╗   ██╗███╗   ██╗ █████╗ ███╗   ███╗██╗ ██████╗
██║     ██╔═══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗    ██╔══██╗╚██╗ ██╔╝████╗  ██║██╔══██╗████╗ ████║██║██╔════╝
██║     ██║   ██║██║     █████╔╝ ██║   ██║██████╔╝    ██║  ██║ ╚████╔╝ ██╔██╗ ██║███████║██╔████╔██║██║██║
██║     ██║   ██║██║     ██╔═██╗ ██║   ██║██╔═══╝     ██║  ██║  ╚██╔╝  ██║╚██╗██║██╔══██║██║╚██╔╝██║██║██║
███████╗╚██████╔╝╚██████╗██║  ██╗╚██████╔╝██║         ██████╔╝   ██║   ██║ ╚████║██║  ██║██║ ╚═╝ ██║██║╚██████╗
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝         ╚═════╝    ╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝ ╚═════╝

*/

/// @title SablierV2LockupDynamic
/// @notice See the documentation in {ISablierV2LockupDynamic}.
contract SablierV2LockupDynamic is
    ISablierV2LockupDynamic, // 1 inherited component
    SablierV2Lockup // 14 inherited components
{
    using CastingUint128 for uint128;
    using CastingUint40 for uint40;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2LockupDynamic
    uint256 public immutable override MAX_SEGMENT_COUNT;

    /*//////////////////////////////////////////////////////////////////////////
                                  PRIVATE STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Sablier V2 Lockup Dynamic streams mapped by unsigned integer ids.
    mapping(uint256 id => LockupDynamic.Stream stream) private _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits a {TransferAdmin} event.
    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialComptroller The address of the initial comptroller.
    /// @param initialNFTDescriptor The address of the NFT descriptor contract.
    /// @param maxSegmentCount The maximum number of segments allowed in a stream.
    constructor(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        ISablierV2NFTDescriptor initialNFTDescriptor,
        uint256 maxSegmentCount
    )
        ERC721("Sablier V2 Lockup Dynamic NFT", "SAB-V2-LOCKUP-DYN")
        SablierV2Lockup(initialAdmin, initialComptroller, initialNFTDescriptor)
    {
        MAX_SEGMENT_COUNT = maxSegmentCount;
        nextStreamId = 1;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    function getAsset(uint256 streamId) external view override notNull(streamId) returns (IERC20 asset) {
        asset = _streams[streamId].asset;
    }

    /// @inheritdoc ISablierV2Lockup
    function getDepositedAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 depositedAmount)
    {
        depositedAmount = _streams[streamId].amounts.deposited;
    }

    /// @inheritdoc ISablierV2Lockup
    function getEndTime(uint256 streamId) external view override notNull(streamId) returns (uint40 endTime) {
        endTime = _streams[streamId].endTime;
    }

    /// @inheritdoc ISablierV2LockupDynamic
    function getRange(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (LockupDynamic.Range memory range)
    {
        range = LockupDynamic.Range({ start: _streams[streamId].startTime, end: _streams[streamId].endTime });
    }

    /// @inheritdoc ISablierV2Lockup
    function getRefundedAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 refundedAmount)
    {
        refundedAmount = _streams[streamId].amounts.refunded;
    }

    /// @inheritdoc ISablierV2LockupDynamic
    function getSegments(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (LockupDynamic.Segment[] memory segments)
    {
        segments = _streams[streamId].segments;
    }

    /// @inheritdoc ISablierV2Lockup
    function getSender(uint256 streamId) external view override notNull(streamId) returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2Lockup
    function getStartTime(uint256 streamId) external view override notNull(streamId) returns (uint40 startTime) {
        startTime = _streams[streamId].startTime;
    }

    /// @inheritdoc ISablierV2LockupDynamic
    function getStream(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (LockupDynamic.Stream memory stream)
    {
        stream = _streams[streamId];

        // Settled streams cannot be canceled.
        if (_statusOf(streamId) == Lockup.Status.SETTLED) {
            stream.isCancelable = false;
        }
    }

    /// @inheritdoc ISablierV2Lockup
    function getWithdrawnAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 withdrawnAmount)
    {
        withdrawnAmount = _streams[streamId].amounts.withdrawn;
    }

    /// @inheritdoc ISablierV2Lockup
    function isCancelable(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        if (_statusOf(streamId) != Lockup.Status.SETTLED) {
            result = _streams[streamId].isCancelable;
        }
    }

    /// @inheritdoc ISablierV2Lockup
    function isCold(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        Lockup.Status status = _statusOf(streamId);
        result = status == Lockup.Status.SETTLED || status == Lockup.Status.CANCELED || status == Lockup.Status.DEPLETED;
    }

    /// @inheritdoc ISablierV2Lockup
    function isDepleted(uint256 streamId)
        public
        view
        override(ISablierV2Lockup, SablierV2Lockup)
        notNull(streamId)
        returns (bool result)
    {
        result = _streams[streamId].isDepleted;
    }

    /// @inheritdoc ISablierV2Lockup
    function isStream(uint256 streamId) public view override(ISablierV2Lockup, SablierV2Lockup) returns (bool result) {
        result = _streams[streamId].isStream;
    }

    /// @inheritdoc ISablierV2Lockup
    function isWarm(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        Lockup.Status status = _statusOf(streamId);
        result = status == Lockup.Status.PENDING || status == Lockup.Status.STREAMING;
    }

    /// @inheritdoc ISablierV2Lockup
    function refundableAmountOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 refundableAmount)
    {
        // These checks are needed because {_calculateStreamedAmount} does not look up the stream's status. Note that
        // checking for `isCancelable` also checks if the stream `wasCanceled` thanks to the protocol invariant that
        // canceled streams are not cancelable anymore.
        if (_streams[streamId].isCancelable && !_streams[streamId].isDepleted) {
            refundableAmount = _streams[streamId].amounts.deposited - _calculateStreamedAmount(streamId);
        }
        // Otherwise, the result is implicitly zero.
    }

    /// @inheritdoc ISablierV2Lockup
    function statusOf(uint256 streamId) external view override notNull(streamId) returns (Lockup.Status status) {
        status = _statusOf(streamId);
    }

    /// @inheritdoc ISablierV2LockupDynamic
    function streamedAmountOf(uint256 streamId)
        public
        view
        override(ISablierV2Lockup, ISablierV2LockupDynamic)
        notNull(streamId)
        returns (uint128 streamedAmount)
    {
        streamedAmount = _streamedAmountOf(streamId);
    }

    /// @inheritdoc ISablierV2Lockup
    function wasCanceled(uint256 streamId)
        public
        view
        override(ISablierV2Lockup, SablierV2Lockup)
        notNull(streamId)
        returns (bool result)
    {
        result = _streams[streamId].wasCanceled;
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2LockupDynamic
    function createWithDeltas(LockupDynamic.CreateWithDeltas calldata params)
        external
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks: check the deltas and generate the canonical segments.
        LockupDynamic.Segment[] memory segments = Helpers.checkDeltasAndCalculateMilestones(params.segments);

        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithMilestones(
            LockupDynamic.CreateWithMilestones({
                asset: params.asset,
                broker: params.broker,
                cancelable: params.cancelable,
                recipient: params.recipient,
                segments: segments,
                sender: params.sender,
                startTime: uint40(block.timestamp),
                totalAmount: params.totalAmount
            })
        );
    }

    /// @inheritdoc ISablierV2LockupDynamic
    function createWithMilestones(LockupDynamic.CreateWithMilestones calldata params)
        external
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithMilestones(params);
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Calculates the streamed amount without looking up the stream's status.
    function _calculateStreamedAmount(uint256 streamId) internal view returns (uint128) {
        // If the start time is in the future, return zero.
        uint40 currentTime = uint40(block.timestamp);
        if (_streams[streamId].startTime >= currentTime) {
            return 0;
        }

        // If the end time is not in the future, return the deposited amount.
        uint40 endTime = _streams[streamId].endTime;
        if (endTime <= currentTime) {
            return _streams[streamId].amounts.deposited;
        }

        if (_streams[streamId].segments.length > 1) {
            // If there is more than one segment, it may be necessary to iterate over all of them.
            return _calculateStreamedAmountForMultipleSegments(streamId);
        } else {
            // Otherwise, there is only one segment, and the calculation is simpler.
            return _calculateStreamedAmountForOneSegment(streamId);
        }
    }

    /// @dev Calculates the streamed amount for a stream with multiple segments.
    ///
    /// Notes:
    ///
    /// 1. Normalization to 18 decimals is not needed because there is no mix of amounts with different decimals.
    /// 2. The stream's start time must be in the past so that the calculations below do not overflow.
    /// 3. The stream's end time must be in the future so that the loop below does not panic with an "index out of
    /// bounds" error.
    function _calculateStreamedAmountForMultipleSegments(uint256 streamId) internal view returns (uint128) {
        unchecked {
            uint40 currentTime = uint40(block.timestamp);
            LockupDynamic.Stream memory stream = _streams[streamId];

            // Sum the amounts in all segments that precede the current time.
            uint128 previousSegmentAmounts;
            uint40 currentSegmentMilestone = stream.segments[0].milestone;
            uint256 index = 0;
            while (currentSegmentMilestone < currentTime) {
                previousSegmentAmounts += stream.segments[index].amount;
                index += 1;
                currentSegmentMilestone = stream.segments[index].milestone;
            }

            // After exiting the loop, the current segment is at `index`.
            SD59x18 currentSegmentAmount = stream.segments[index].amount.intoSD59x18();
            SD59x18 currentSegmentExponent = stream.segments[index].exponent.intoSD59x18();
            currentSegmentMilestone = stream.segments[index].milestone;

            uint40 previousMilestone;
            if (index > 0) {
                // When the current segment's index is greater than or equal to 1, it implies that the segment is not
                // the first. In this case, use the previous segment's milestone.
                previousMilestone = stream.segments[index - 1].milestone;
            } else {
                // Otherwise, the current segment is the first, so use the start time as the previous milestone.
                previousMilestone = stream.startTime;
            }

            // Calculate how much time has passed since the segment started, and the total time of the segment.
            SD59x18 elapsedSegmentTime = (currentTime - previousMilestone).intoSD59x18();
            SD59x18 totalSegmentTime = (currentSegmentMilestone - previousMilestone).intoSD59x18();

            // Divide the elapsed segment time by the total duration of the segment.
            SD59x18 elapsedSegmentTimePercentage = elapsedSegmentTime.div(totalSegmentTime);

            // Calculate the streamed amount using the special formula.
            SD59x18 multiplier = elapsedSegmentTimePercentage.pow(currentSegmentExponent);
            SD59x18 segmentStreamedAmount = multiplier.mul(currentSegmentAmount);

            // Although the segment streamed amount should never exceed the total segment amount, this condition is
            // checked without asserting to avoid locking funds in case of a bug. If this situation occurs, the
            // amount streamed in the segment is considered zero (except for past withdrawals), and the segment is
            // effectively voided.
            if (segmentStreamedAmount.gt(currentSegmentAmount)) {
                return previousSegmentAmounts > stream.amounts.withdrawn
                    ? previousSegmentAmounts
                    : stream.amounts.withdrawn;
            }

            // Calculate the total streamed amount by adding the previous segment amounts and the amount streamed in
            // the current segment. Casting to uint128 is safe due to the if statement above.
            return previousSegmentAmounts + uint128(segmentStreamedAmount.intoUint256());
        }
    }

    /// @dev Calculates the streamed amount for a a stream with one segment. Normalization to 18 decimals is not
    /// needed because there is no mix of amounts with different decimals.
    function _calculateStreamedAmountForOneSegment(uint256 streamId) internal view returns (uint128) {
        unchecked {
            // Calculate how much time has passed since the stream started, and the stream's total duration.
            SD59x18 elapsedTime = (uint40(block.timestamp) - _streams[streamId].startTime).intoSD59x18();
            SD59x18 totalTime = (_streams[streamId].endTime - _streams[streamId].startTime).intoSD59x18();

            // Divide the elapsed time by the stream's total duration.
            SD59x18 elapsedTimePercentage = elapsedTime.div(totalTime);

            // Cast the stream parameters to SD59x18.
            SD59x18 exponent = _streams[streamId].segments[0].exponent.intoSD59x18();
            SD59x18 depositedAmount = _streams[streamId].amounts.deposited.intoSD59x18();

            // Calculate the streamed amount using the special formula.
            SD59x18 multiplier = elapsedTimePercentage.pow(exponent);
            SD59x18 streamedAmount = multiplier.mul(depositedAmount);

            // Although the streamed amount should never exceed the deposited amount, this condition is checked
            // without asserting to avoid locking funds in case of a bug. If this situation occurs, the withdrawn
            // amount is considered to be the streamed amount, and the stream is effectively frozen.
            if (streamedAmount.gt(depositedAmount)) {
                return _streams[streamId].amounts.withdrawn;
            }

            // Cast the streamed amount to uint128. This is safe due to the check above.
            return uint128(streamedAmount.intoUint256());
        }
    }

    /// @inheritdoc SablierV2Lockup
    function _isCallerStreamSender(uint256 streamId) internal view override returns (bool) {
        return msg.sender == _streams[streamId].sender;
    }

    /// @inheritdoc SablierV2Lockup
    function _statusOf(uint256 streamId) internal view override returns (Lockup.Status) {
        if (_streams[streamId].isDepleted) {
            return Lockup.Status.DEPLETED;
        } else if (_streams[streamId].wasCanceled) {
            return Lockup.Status.CANCELED;
        }

        if (block.timestamp < _streams[streamId].startTime) {
            return Lockup.Status.PENDING;
        }

        if (_calculateStreamedAmount(streamId) < _streams[streamId].amounts.deposited) {
            return Lockup.Status.STREAMING;
        } else {
            return Lockup.Status.SETTLED;
        }
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _streamedAmountOf(uint256 streamId) internal view returns (uint128) {
        Lockup.Amounts memory amounts = _streams[streamId].amounts;

        if (_streams[streamId].isDepleted) {
            return amounts.withdrawn;
        } else if (_streams[streamId].wasCanceled) {
            return amounts.deposited - amounts.refunded;
        }

        return _calculateStreamedAmount(streamId);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _withdrawableAmountOf(uint256 streamId) internal view override returns (uint128) {
        return _streamedAmountOf(streamId) - _streams[streamId].amounts.withdrawn;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _cancel(uint256 streamId) internal override {
        // Calculate the streamed amount.
        uint128 streamedAmount = _calculateStreamedAmount(streamId);

        // Retrieve the amounts from storage.
        Lockup.Amounts memory amounts = _streams[streamId].amounts;

        // Checks: the stream is not settled.
        if (streamedAmount >= amounts.deposited) {
            revert Errors.SablierV2Lockup_StreamSettled(streamId);
        }

        // Checks: the stream is cancelable.
        if (!_streams[streamId].isCancelable) {
            revert Errors.SablierV2Lockup_StreamNotCancelable(streamId);
        }

        // Calculate the sender's and the recipient's amount.
        uint128 senderAmount = amounts.deposited - streamedAmount;
        uint128 recipientAmount = streamedAmount - amounts.withdrawn;

        // Effects: mark the stream as canceled.
        _streams[streamId].wasCanceled = true;

        // Effects: make the stream not cancelable anymore, because a stream can only be canceled once.
        _streams[streamId].isCancelable = false;

        // Effects: If there are no assets left for the recipient to withdraw, mark the stream as depleted.
        if (recipientAmount == 0) {
            _streams[streamId].isDepleted = true;
        }

        // Effects: set the refunded amount.
        _streams[streamId].amounts.refunded = senderAmount;

        // Retrieve the sender and the recipient from storage.
        address sender = _streams[streamId].sender;
        address recipient = _ownerOf(streamId);

        // Interactions: refund the sender.
        _streams[streamId].asset.safeTransfer({ to: sender, value: senderAmount });

        // Interactions: if `msg.sender` is the sender and the recipient is a contract, try to invoke the cancel
        // hook on the recipient without reverting if the hook is not implemented, and without bubbling up any
        // potential revert.
        if (msg.sender == sender) {
            if (recipient.code.length > 0) {
                try ISablierV2LockupRecipient(recipient).onStreamCanceled({
                    streamId: streamId,
                    sender: sender,
                    senderAmount: senderAmount,
                    recipientAmount: recipientAmount
                }) { } catch { }
            }
        }
        // Interactions: if `msg.sender` is the recipient and the sender is a contract, try to invoke the cancel
        // hook on the sender without reverting if the hook is not implemented, and also without bubbling up any
        // potential revert.
        else {
            if (sender.code.length > 0) {
                try ISablierV2LockupSender(sender).onStreamCanceled({
                    streamId: streamId,
                    recipient: recipient,
                    senderAmount: senderAmount,
                    recipientAmount: recipientAmount
                }) { } catch { }
            }
        }

        // Log the cancellation.
        emit ISablierV2Lockup.CancelLockupStream(streamId, sender, recipient, senderAmount, recipientAmount);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _createWithMilestones(LockupDynamic.CreateWithMilestones memory params)
        internal
        returns (uint256 streamId)
    {
        // Safe Interactions: query the protocol fee. This is safe because it's a known Sablier contract that does
        // not call other unknown contracts.
        UD60x18 protocolFee = comptroller.protocolFees(params.asset);

        // Checks: check the fees and calculate the fee amounts.
        Lockup.CreateAmounts memory createAmounts =
            Helpers.checkAndCalculateFees(params.totalAmount, protocolFee, params.broker.fee, MAX_FEE);

        // Checks: validate the user-provided parameters.
        Helpers.checkCreateWithMilestones(createAmounts.deposit, params.segments, MAX_SEGMENT_COUNT, params.startTime);

        // Load the stream id in a variable.
        streamId = nextStreamId;

        // Effects: create the stream.
        LockupDynamic.Stream storage stream = _streams[streamId];
        stream.amounts.deposited = createAmounts.deposit;
        stream.asset = params.asset;
        stream.isCancelable = params.cancelable;
        stream.isStream = true;
        stream.sender = params.sender;

        unchecked {
            // The segment count cannot be zero at this point.
            uint256 segmentCount = params.segments.length;
            stream.endTime = params.segments[segmentCount - 1].milestone;
            stream.startTime = params.startTime;

            // Effects: store the segments. Since Solidity lacks a syntax for copying arrays directly from
            // memory to storage, a manual approach is necessary. See https://github.com/ethereum/solidity/issues/12783.
            for (uint256 i = 0; i < segmentCount; ++i) {
                stream.segments.push(params.segments[i]);
            }

            // Effects: bump the next stream id and record the protocol fee.
            // Using unchecked arithmetic because these calculations cannot realistically overflow, ever.
            nextStreamId = streamId + 1;
            protocolRevenues[params.asset] = protocolRevenues[params.asset] + createAmounts.protocolFee;
        }

        // Effects: mint the NFT to the recipient.
        _mint({ to: params.recipient, tokenId: streamId });

        // Interactions: transfer the deposit and the protocol fee.
        // Using unchecked arithmetic because the deposit and the protocol fee are bounded by the total amount.
        unchecked {
            params.asset.safeTransferFrom({
                from: msg.sender,
                to: address(this),
                value: createAmounts.deposit + createAmounts.protocolFee
            });
        }

        // Interactions: pay the broker fee, if not zero.
        if (createAmounts.brokerFee > 0) {
            params.asset.safeTransferFrom({ from: msg.sender, to: params.broker.account, value: createAmounts.brokerFee });
        }

        // Log the newly created stream.
        emit ISablierV2LockupDynamic.CreateLockupDynamicStream({
            streamId: streamId,
            funder: msg.sender,
            sender: params.sender,
            recipient: params.recipient,
            amounts: createAmounts,
            asset: params.asset,
            cancelable: params.cancelable,
            segments: params.segments,
            range: LockupDynamic.Range({ start: stream.startTime, end: stream.endTime }),
            broker: params.broker.account
        });
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _renounce(uint256 streamId) internal override {
        // Checks: the stream is cancelable.
        if (!_streams[streamId].isCancelable) {
            revert Errors.SablierV2Lockup_StreamNotCancelable(streamId);
        }

        // Effects: renounce the stream by making it not cancelable.
        _streams[streamId].isCancelable = false;

        // Interactions: if the recipient is a contract, try to invoke the renounce hook on the recipient without
        // reverting if the hook is not implemented, and also without bubbling up any potential revert.
        address recipient = _ownerOf(streamId);
        if (recipient.code.length > 0) {
            try ISablierV2LockupRecipient(recipient).onStreamRenounced(streamId) { } catch { }
        }

        // Log the renouncement.
        emit ISablierV2Lockup.RenounceLockupStream(streamId);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal override {
        // Checks: the withdraw amount is not greater than the withdrawable amount.
        uint128 withdrawableAmount = _withdrawableAmountOf(streamId);
        if (amount > withdrawableAmount) {
            revert Errors.SablierV2Lockup_Overdraw(streamId, amount, withdrawableAmount);
        }

        // Effects: update the withdrawn amount.
        _streams[streamId].amounts.withdrawn = _streams[streamId].amounts.withdrawn + amount;

        // Retrieve the amounts from storage.
        Lockup.Amounts memory amounts = _streams[streamId].amounts;

        // Using ">=" instead of "==" for additional safety reasons. In the event of an unforeseen increase in the
        // withdrawn amount, the stream will still be marked as depleted.
        if (amounts.withdrawn >= amounts.deposited - amounts.refunded) {
            // Effects: mark the stream as depleted.
            _streams[streamId].isDepleted = true;

            // Effects: make the stream not cancelable anymore, because a depleted stream cannot be canceled.
            _streams[streamId].isCancelable = false;
        }

        // Interactions: perform the ERC-20 transfer.
        _streams[streamId].asset.safeTransfer({ to: to, value: amount });

        // Retrieve the recipient from storage.
        address recipient = _ownerOf(streamId);

        // Interactions: if `msg.sender` is not the recipient and the recipient is a contract, try to invoke the
        // withdraw hook on it without reverting if the hook is not implemented, and also without bubbling up
        // any potential revert.
        if (msg.sender != recipient && recipient.code.length > 0) {
            try ISablierV2LockupRecipient(recipient).onStreamWithdrawn({
                streamId: streamId,
                caller: msg.sender,
                to: to,
                amount: amount
            }) { } catch { }
        }

        // Log the withdrawal.
        emit ISablierV2Lockup.WithdrawFromLockupStream(streamId, to, amount);
    }
}
