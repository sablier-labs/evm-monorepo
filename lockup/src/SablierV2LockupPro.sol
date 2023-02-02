// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/token/ERC721/ERC721.sol";
import { IERC721Metadata } from "@openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/casting/Uint128.sol";
import { PRBMathCastingUint40 as CastingUint40 } from "@prb/math/casting/Uint40.sol";
import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { SablierV2Lockup } from "./abstracts/SablierV2Lockup.sol";
import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Lockup } from "./interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupPro } from "./interfaces/ISablierV2LockupPro.sol";
import { ISablierV2LockupRecipient } from "./interfaces/hooks/ISablierV2LockupRecipient.sol";
import { ISablierV2LockupSender } from "./interfaces/hooks/ISablierV2LockupSender.sol";
import { Errors } from "./libraries/Errors.sol";
import { Events } from "./libraries/Events.sol";
import { Helpers } from "./libraries/Helpers.sol";
import { Broker, Lockup, LockupPro } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ██╗   ██╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██║   ██║╚════██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    ██║   ██║ █████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ╚██╗ ██╔╝██╔═══╝
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║     ╚████╔╝ ███████╗
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚══════╝

██╗      ██████╗  ██████╗██╗  ██╗██╗   ██╗██████╗     ██████╗ ██████╗  ██████╗
██║     ██╔═══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗    ██╔══██╗██╔══██╗██╔═══██╗
██║     ██║   ██║██║     █████╔╝ ██║   ██║██████╔╝    ██████╔╝██████╔╝██║   ██║
██║     ██║   ██║██║     ██╔═██╗ ██║   ██║██╔═══╝     ██╔═══╝ ██╔══██╗██║   ██║
███████╗╚██████╔╝╚██████╗██║  ██╗╚██████╔╝██║         ██║     ██║  ██║╚██████╔╝
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝         ╚═╝     ╚═╝  ╚═╝ ╚═════╝

*/

/// @title SablierV2LockupPro
/// @dev This contract implements the {ISablierV2LockupPro} interface.
contract SablierV2LockupPro is
    ISablierV2LockupPro, // one dependency
    ERC721("Sablier V2 Pro NFT", "SAB-V2-PRO"), // six dependencies
    SablierV2Lockup // ten dependencies
{
    using CastingUint128 for uint128;
    using CastingUint40 for uint40;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2LockupPro
    uint256 public immutable override MAX_SEGMENT_COUNT;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Sablier V2 pro streams mapped by unsigned integers.
    mapping(uint256 => LockupPro.Stream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits a {TransferAdmin} event.
    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialComptroller The address of the initial comptroller.
    /// @param maxFee The maximum fee that can be charged by either the protocol or a broker, as an UD60x18 number
    /// where 100% = 1e18.
    /// @param maxSegmentCount The maximum number of segments permitted in a stream.
    constructor(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) SablierV2Lockup(initialAdmin, initialComptroller, maxFee) {
        MAX_SEGMENT_COUNT = maxSegmentCount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    function getAsset(uint256 streamId) external view override returns (IERC20 asset) {
        asset = _streams[streamId].asset;
    }

    /// @inheritdoc ISablierV2Lockup
    function getDepositAmount(uint256 streamId) external view override returns (uint128 depositAmount) {
        depositAmount = _streams[streamId].amounts.deposit;
    }

    /// @inheritdoc ISablierV2Lockup
    function getEndTime(uint256 streamId) external view override returns (uint40 endTime) {
        endTime = _streams[streamId].range.end;
    }

    /// @inheritdoc ISablierV2LockupPro
    function getRange(uint256 streamId) external view override returns (LockupPro.Range memory range) {
        range = _streams[streamId].range;
    }

    /// @inheritdoc ISablierV2Lockup
    function getRecipient(
        uint256 streamId
    ) public view override(ISablierV2Lockup, SablierV2Lockup) returns (address recipient) {
        recipient = _ownerOf(streamId);
    }

    /// @inheritdoc ISablierV2LockupPro
    function getSegments(uint256 streamId) external view override returns (LockupPro.Segment[] memory segments) {
        segments = _streams[streamId].segments;
    }

    /// @inheritdoc ISablierV2Lockup
    function getSender(uint256 streamId) external view override returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2Lockup
    function getStartTime(uint256 streamId) external view override returns (uint40 startTime) {
        startTime = _streams[streamId].range.start;
    }

    /// @inheritdoc ISablierV2Lockup
    function getStatus(
        uint256 streamId
    ) public view virtual override(ISablierV2Lockup, SablierV2Lockup) returns (Lockup.Status status) {
        status = _streams[streamId].status;
    }

    /// @inheritdoc ISablierV2LockupPro
    function getStream(uint256 streamId) external view override returns (LockupPro.Stream memory stream) {
        stream = _streams[streamId];
    }

    /// @inheritdoc ISablierV2Lockup
    function getWithdrawnAmount(uint256 streamId) external view override returns (uint128 withdrawnAmount) {
        withdrawnAmount = _streams[streamId].amounts.withdrawn;
    }

    /// @inheritdoc ISablierV2Lockup
    function isCancelable(
        uint256 streamId
    ) public view override(ISablierV2Lockup, SablierV2Lockup) returns (bool result) {
        // A null stream dot not exist, and a canceled or depleted stream cannot be canceled anymore.
        if (_streams[streamId].status != Lockup.Status.ACTIVE) {
            return false;
        }
        result = _streams[streamId].isCancelable;
    }

    /// @inheritdoc ISablierV2Lockup
    function returnableAmountOf(uint256 streamId) external view override returns (uint128 returnableAmount) {
        // When the stream is not active, return zero.
        if (_streams[streamId].status != Lockup.Status.ACTIVE) {
            return 0;
        }

        // No need for an assertion here, since the {streamedAmountOf} function checks that the deposit amount
        // is greater than or equal to the streamed amount.
        unchecked {
            returnableAmount = _streams[streamId].amounts.deposit - streamedAmountOf(streamId);
        }
    }

    /// @inheritdoc ISablierV2Lockup
    function streamedAmountOf(uint256 streamId) public view override returns (uint128 streamedAmount) {
        // When the stream is null, return zero. When the stream is canceled or depleted, return the withdrawn
        // amount.
        if (_streams[streamId].status != Lockup.Status.ACTIVE) {
            return _streams[streamId].amounts.withdrawn;
        }

        // If the start time is greater than or equal to the block timestamp, return zero.
        uint40 currentTime = uint40(block.timestamp);
        if (_streams[streamId].range.start >= currentTime) {
            return 0;
        }

        uint256 segmentCount = _streams[streamId].segments.length;
        uint40 endTime = _streams[streamId].range.end;

        // If the current time is greater than or equal to the end time, we simply return the deposit minus
        // the withdrawn amount.
        if (currentTime >= endTime) {
            return _streams[streamId].amounts.deposit;
        }

        if (segmentCount > 1) {
            // If there's more than one segment, we have to iterate over all of them.
            streamedAmount = _calculateStreamedAmountForMultipleSegments(streamId);
        } else {
            // Otherwise, there is only one segment, and the calculation is simple.
            streamedAmount = _calculateStreamedAmountForOneSegment(streamId);
        }
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 streamId) public pure override(IERC721Metadata, ERC721) returns (string memory uri) {
        streamId;
        uri = "";
    }

    /// @inheritdoc ISablierV2Lockup
    function withdrawableAmountOf(
        uint256 streamId
    ) public view override(ISablierV2Lockup, SablierV2Lockup) returns (uint128 withdrawableAmount) {
        unchecked {
            withdrawableAmount = streamedAmountOf(streamId) - _streams[streamId].amounts.withdrawn;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2LockupPro
    function createWithDeltas(
        address sender,
        address recipient,
        uint128 totalAmount,
        LockupPro.Segment[] memory segments,
        IERC20 asset,
        bool cancelable,
        uint40[] calldata deltas,
        Broker calldata broker
    ) external override returns (uint256 streamId) {
        // Checks: check the deltas and adjust the segments accordingly.
        Helpers.checkDeltasAndAdjustSegments(segments, deltas);

        // Safe Interactions: query the protocol fee. This is safe because it's a known Sablier contract.
        UD60x18 protocolFee = comptroller.getProtocolFee(asset);

        // Checks: check the fees and calculate the fee amounts.
        Lockup.CreateAmounts memory amounts = Helpers.checkAndCalculateFees(
            totalAmount,
            protocolFee,
            broker.fee,
            MAX_FEE
        );

        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithMilestones(
            CreateWithMilestonesParams({
                amounts: amounts,
                broker: broker.addr,
                cancelable: cancelable,
                recipient: recipient,
                segments: segments,
                sender: sender,
                asset: asset,
                startTime: uint40(block.timestamp)
            })
        );
    }

    /// @inheritdoc ISablierV2LockupPro
    function createWithMilestones(
        address sender,
        address recipient,
        uint128 totalAmount,
        LockupPro.Segment[] calldata segments,
        IERC20 asset,
        bool cancelable,
        uint40 startTime,
        Broker calldata broker
    ) external override returns (uint256 streamId) {
        // Safe Interactions: query the protocol fee. This is safe because it's a known Sablier contract.
        UD60x18 protocolFee = comptroller.getProtocolFee(asset);

        // Checks: check the fees and calculate the fee amounts.
        Lockup.CreateAmounts memory amounts = Helpers.checkAndCalculateFees(
            totalAmount,
            protocolFee,
            broker.fee,
            MAX_FEE
        );

        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithMilestones(
            CreateWithMilestonesParams({
                amounts: amounts,
                broker: broker.addr,
                cancelable: cancelable,
                recipient: recipient,
                segments: segments,
                sender: sender,
                asset: asset,
                startTime: startTime
            })
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Calculates the withdrawable amount for a stream with multiple segments.
    ///
    /// IMPORTANT: this function must be called only after checking that the current time is less than the last
    /// segment's milestone, lest the loop below encounters an "index out of bounds" error.
    function _calculateStreamedAmountForMultipleSegments(
        uint256 streamId
    ) internal view returns (uint128 streamedAmount) {
        unchecked {
            uint40 currentTime = uint40(block.timestamp);

            // Sum up the amounts found in all preceding segments.
            uint128 previousSegmentAmounts;
            uint40 currentSegmentMilestone = _streams[streamId].segments[0].milestone;
            uint256 index = 1;
            while (currentSegmentMilestone < currentTime) {
                previousSegmentAmounts += _streams[streamId].segments[index - 1].amount;
                currentSegmentMilestone = _streams[streamId].segments[index].milestone;
                index += 1;
            }

            // After the loop exits, the current segment is found at index `index - 1`, whereas the previous segment
            // is found at `index - 2` (if there are at least two segments).
            SD59x18 currentSegmentAmount = _streams[streamId].segments[index - 1].amount.intoSD59x18();
            SD59x18 currentSegmentExponent = _streams[streamId].segments[index - 1].exponent.intoSD59x18();
            currentSegmentMilestone = _streams[streamId].segments[index - 1].milestone;

            uint40 previousMilestone;
            if (index > 1) {
                // If the current segment is at an index that is >= 2, use the previous segment's milestone.
                previousMilestone = _streams[streamId].segments[index - 2].milestone;
            } else {
                // Otherwise, there is only one segment, so use the start of the stream as the previous milestone.
                previousMilestone = _streams[streamId].range.start;
            }

            // Calculate how much time has elapsed since the segment started, and the total time of the segment.
            SD59x18 elapsedSegmentTime = (currentTime - previousMilestone).intoSD59x18();
            SD59x18 totalSegmentTime = (currentSegmentMilestone - previousMilestone).intoSD59x18();

            // Calculate the streamed amount.
            SD59x18 elapsedSegmentTimePercentage = elapsedSegmentTime.div(totalSegmentTime);
            SD59x18 multiplier = elapsedSegmentTimePercentage.pow(currentSegmentExponent);
            SD59x18 segmentStreamedAmount = multiplier.mul(currentSegmentAmount);

            // Assert that the streamed amount is lower than or equal to the current segment amount.
            assert(segmentStreamedAmount.lte(currentSegmentAmount));

            // Finally, calculate the streamed amount by adding up the previous segment amounts and the amount
            // streamed in this segment. Casting to uint128 is safe thanks to the assertion above.
            streamedAmount = previousSegmentAmounts + uint128(segmentStreamedAmount.intoUint256());
        }
    }

    /// @dev Calculates the withdrawable amount for a stream with one segment.
    function _calculateStreamedAmountForOneSegment(uint256 streamId) internal view returns (uint128 streamedAmount) {
        unchecked {
            // Load the stream fields as SD59x18 numbers.
            SD59x18 depositAmount = _streams[streamId].amounts.deposit.intoSD59x18();
            SD59x18 exponent = _streams[streamId].segments[0].exponent.intoSD59x18();

            // Calculate how much time has elapsed since the stream started, and the total time of the stream.
            SD59x18 elapsedTime = (uint40(block.timestamp) - _streams[streamId].range.start).intoSD59x18();
            SD59x18 totalTime = (_streams[streamId].range.end - _streams[streamId].range.start).intoSD59x18();

            // Calculate the streamed amount.
            SD59x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            SD59x18 multiplier = elapsedTimePercentage.pow(exponent);
            SD59x18 streamedAmountUd = multiplier.mul(depositAmount);

            // Assert that the streamed amount is lower than or equal to the deposit amount.
            assert(streamedAmountUd.lte(depositAmount));

            // Casting to uint128 is safe thanks for the assertion above.
            streamedAmount = uint128(streamedAmountUd.intoUint256());
        }
    }

    /// @inheritdoc SablierV2Lockup
    function _isApprovedOrOwner(
        uint256 streamId,
        address spender
    ) internal view override returns (bool isApprovedOrOwner) {
        address owner = _ownerOf(streamId);
        isApprovedOrOwner = (spender == owner || isApprovedForAll(owner, spender) || getApproved(streamId) == spender);
    }

    /// @inheritdoc SablierV2Lockup
    function _isCallerStreamSender(uint256 streamId) internal view override returns (bool result) {
        result = msg.sender == _streams[streamId].sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the public functions that call this internal function.
    function _burn(uint256 tokenId) internal override(ERC721, SablierV2Lockup) {
        ERC721._burn(tokenId);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _cancel(uint256 streamId) internal override onlySenderOrRecipient(streamId) {
        LockupPro.Stream memory stream = _streams[streamId];

        // Calculate the sender's and the recipient's amount.
        uint128 senderAmount;
        uint128 recipientAmount = withdrawableAmountOf(streamId);
        unchecked {
            senderAmount = stream.amounts.deposit - stream.amounts.withdrawn - recipientAmount;
        }

        // Load the sender and the recipient in memory, they are needed multiple times below.
        address sender = _streams[streamId].sender;
        address recipient = _ownerOf(streamId);

        // Effects: mark the stream as canceled.
        _streams[streamId].status = Lockup.Status.CANCELED;

        // Interactions: return the assets to the sender, if any.
        if (senderAmount > 0) {
            stream.asset.safeTransfer({ to: sender, value: senderAmount });
        }

        if (recipientAmount > 0) {
            // Effects: add the recipient's amount to the withdrawn amount.
            unchecked {
                _streams[streamId].amounts.withdrawn += recipientAmount;
            }

            // Interactions: withdraw the tokens to the recipient.
            stream.asset.safeTransfer({ to: recipient, value: recipientAmount });
        }

        // Interactions: if the `msg.sender` is the sender and the recipient is a contract, try to invoke the cancel
        // hook on the recipient without reverting if the hook is not implemented, and without bubbling up any
        // potential revert.
        if (msg.sender == sender) {
            if (recipient.code.length > 0) {
                try
                    ISablierV2LockupRecipient(recipient).onStreamCanceled({
                        streamId: streamId,
                        senderAmount: senderAmount,
                        recipientAmount: recipientAmount
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
                    ISablierV2LockupSender(sender).onStreamCanceled({
                        streamId: streamId,
                        senderAmount: senderAmount,
                        recipientAmount: recipientAmount
                    })
                {} catch {}
            }
        }

        // Log the cancellation.
        emit Events.CancelLockupStream(streamId, sender, recipient, senderAmount, recipientAmount);
    }

    /// @dev This struct is needed to avoid the "Stack Too Deep" error.
    struct CreateWithMilestonesParams {
        Lockup.CreateAmounts amounts;
        LockupPro.Segment[] segments;
        address sender; // ──┐
        uint40 startTime; // │
        bool cancelable; // ─┘
        address recipient;
        IERC20 asset;
        address broker;
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _createWithMilestones(CreateWithMilestonesParams memory params) internal returns (uint256 streamId) {
        // Checks: validate the arguments.
        Helpers.checkCreateProParams(params.amounts.deposit, params.segments, MAX_SEGMENT_COUNT, params.startTime);

        // Load the stream id.
        streamId = nextStreamId;

        // Load the segment count.
        uint256 segmentCount = params.segments.length;

        // Effects: create the stream.
        LockupPro.Stream storage stream = _streams[streamId];
        stream.amounts = Lockup.Amounts({ deposit: params.amounts.deposit, withdrawn: 0 });
        stream.asset = params.asset;
        stream.isCancelable = params.cancelable;
        stream.sender = params.sender;
        stream.status = Lockup.Status.ACTIVE;

        unchecked {
            // The segment count cannot be zero at this point.
            stream.range = LockupPro.Range({
                start: params.startTime,
                end: params.segments[segmentCount - 1].milestone
            });

            // Effects: store the segments. Copying an array from memory to storage is not currently supported in
            // Solidity, so it has to be done manually. See https://github.com/ethereum/solidity/issues/12783
            for (uint256 i = 0; i < segmentCount; ++i) {
                stream.segments.push(params.segments[i]);
            }

            // Effects: bump the next stream id and record the protocol fee.
            // Using unchecked arithmetic because these calculations cannot realistically overflow, ever.
            nextStreamId = streamId + 1;
            _protocolRevenues[params.asset] += params.amounts.protocolFee;
        }

        // Effects: mint the NFT to the recipient.
        _mint({ to: params.recipient, tokenId: streamId });

        // Interactions: transfer the deposit and the protocol fee.
        // Using unchecked arithmetic because the deposit and the protocol fee are bounded by the total amount.
        unchecked {
            params.asset.safeTransferFrom({
                from: msg.sender,
                to: address(this),
                value: params.amounts.deposit + params.amounts.protocolFee
            });
        }

        // Interactions: pay the broker fee, if not zero.
        if (params.amounts.brokerFee > 0) {
            params.asset.safeTransferFrom({ from: msg.sender, to: params.broker, value: params.amounts.brokerFee });
        }

        // Log the newly created stream, and the address that funded it.
        emit Events.CreateLockupProStream({
            streamId: streamId,
            funder: msg.sender,
            sender: params.sender,
            recipient: params.recipient,
            amounts: params.amounts,
            segments: params.segments,
            asset: params.asset,
            cancelable: params.cancelable,
            range: stream.range,
            broker: params.broker
        });
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _renounce(uint256 streamId) internal override {
        // Effects: make the stream non-cancelable.
        _streams[streamId].isCancelable = false;

        // Interactions: if the recipient is a contract, try to invoke the renounce hook on the recipient without
        // reverting if the hook is not implemented, and also without bubbling up any potential revert.
        address recipient = _ownerOf(streamId);
        if (recipient.code.length > 0) {
            try ISablierV2LockupRecipient(recipient).onStreamRenounced(streamId) {} catch {}
        }

        // Log the renouncement.
        emit Events.RenounceLockupStream(streamId);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal override {
        // Checks: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2Lockup_WithdrawAmountZero(streamId);
        }

        // Checks: the amount is not greater than what can be withdrawn.
        uint128 withdrawableAmount = withdrawableAmountOf(streamId);
        if (amount > withdrawableAmount) {
            revert Errors.SablierV2Lockup_WithdrawAmountGreaterThanWithdrawableAmount(
                streamId,
                amount,
                withdrawableAmount
            );
        }

        // Effects: update the withdrawn amount.
        unchecked {
            _streams[streamId].amounts.withdrawn += amount;
        }

        // Load the stream and the recipient in memory, they will be needed below.
        LockupPro.Stream memory stream = _streams[streamId];
        address recipient = _ownerOf(streamId);

        // Assert that the withdrawn amount is greater than or equal to the deposit amount.
        assert(stream.amounts.deposit >= stream.amounts.withdrawn);

        // Effects: if the entire deposit amount is now withdrawn, mark the stream as depleted.
        if (stream.amounts.deposit == stream.amounts.withdrawn) {
            _streams[streamId].status = Lockup.Status.DEPLETED;
        }

        // Interactions: perform the ERC-20 transfer.
        stream.asset.safeTransfer({ to: to, value: amount });

        // Interactions: if the `msg.sender` is not the recipient and the recipient is a contract, try to invoke the
        // withdraw hook on it without reverting if the hook is not implemented, and also without bubbling up
        // any potential revert.
        if (msg.sender != recipient && recipient.code.length > 0) {
            try
                ISablierV2LockupRecipient(recipient).onStreamWithdrawn({
                    streamId: streamId,
                    caller: msg.sender,
                    to: to,
                    amount: amount
                })
            {} catch {}
        }

        // Log the withdrawal.
        emit Events.WithdrawFromLockupStream(streamId, to, amount);
    }
}
