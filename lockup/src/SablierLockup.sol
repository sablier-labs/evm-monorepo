// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { SablierLockupBase } from "./abstracts/SablierLockupBase.sol";
import { ILockupNFTDescriptor } from "./interfaces/ILockupNFTDescriptor.sol";
import { ISablierLockup } from "./interfaces/ISablierLockup.sol";
import { Errors } from "./libraries/Errors.sol";
import { Helpers } from "./libraries/Helpers.sol";
import { VestingMath } from "./libraries/VestingMath.sol";
import { Lockup, LockupDynamic, LockupLinear, LockupTranched } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ██╗      ██████╗  ██████╗██╗  ██╗██╗   ██╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██║     ██╔═══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    ██║     ██║   ██║██║     █████╔╝ ██║   ██║██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ██║     ██║   ██║██║     ██╔═██╗ ██║   ██║██╔═══╝
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║    ███████╗╚██████╔╝╚██████╗██║  ██╗╚██████╔╝██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝

*/

/// @title SablierLockup
/// @notice See the documentation in {ISablierLockup}.
contract SablierLockup is ISablierLockup, SablierLockupBase {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockup
    uint256 public immutable override MAX_COUNT;

    /// @dev Cliff timestamp mapped by stream IDs. This is used in Lockup Linear models.
    mapping(uint256 streamId => uint40 cliffTime) internal _cliffs;

    /// @dev Stream segments mapped by stream IDs. This is used in Lockup Dynamic models.
    mapping(uint256 streamId => LockupDynamic.Segment[] segments) internal _segments;

    /// @dev Stream tranches mapped by stream IDs. This is used in Lockup Tranched models.
    mapping(uint256 streamId => LockupTranched.Tranche[] tranches) internal _tranches;

    /// @dev Unlock amounts mapped by stream IDs. This is used in Lockup Linear models.
    mapping(uint256 streamId => LockupLinear.UnlockAmounts unlockAmounts) internal _unlockAmounts;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialNFTDescriptor The address of the NFT descriptor contract.
    /// @param maxCount The maximum number of segments and tranched allowed in Lockup Dynamic and Lockup Tranched
    /// models, respectively.
    constructor(
        address initialAdmin,
        ILockupNFTDescriptor initialNFTDescriptor,
        uint256 maxCount
    )
        ERC721("Sablier Lockup NFT", "SAB-LOCKUP")
        SablierLockupBase(initialAdmin, initialNFTDescriptor)
    {
        MAX_COUNT = maxCount;
        nextStreamId = 1;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockup
    function getCliffTime(uint256 streamId) external view override notNull(streamId) returns (uint40 cliffTime) {
        if (_streams[streamId].lockupModel != Lockup.Model.LOCKUP_LINEAR) {
            revert Errors.SablierLockup_NotExpectedModel(_streams[streamId].lockupModel, Lockup.Model.LOCKUP_LINEAR);
        }

        cliffTime = _cliffs[streamId];
    }

    /// @inheritdoc ISablierLockup
    function getSegments(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (LockupDynamic.Segment[] memory segments)
    {
        if (_streams[streamId].lockupModel != Lockup.Model.LOCKUP_DYNAMIC) {
            revert Errors.SablierLockup_NotExpectedModel(_streams[streamId].lockupModel, Lockup.Model.LOCKUP_DYNAMIC);
        }

        segments = _segments[streamId];
    }

    /// @inheritdoc ISablierLockup
    function getTranches(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (LockupTranched.Tranche[] memory tranches)
    {
        if (_streams[streamId].lockupModel != Lockup.Model.LOCKUP_TRANCHED) {
            revert Errors.SablierLockup_NotExpectedModel(_streams[streamId].lockupModel, Lockup.Model.LOCKUP_TRANCHED);
        }

        tranches = _tranches[streamId];
    }

    /// @inheritdoc ISablierLockup
    function getUnlockAmounts(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (LockupLinear.UnlockAmounts memory unlockAmounts)
    {
        if (_streams[streamId].lockupModel != Lockup.Model.LOCKUP_LINEAR) {
            revert Errors.SablierLockup_NotExpectedModel(_streams[streamId].lockupModel, Lockup.Model.LOCKUP_LINEAR);
        }

        unlockAmounts = _unlockAmounts[streamId];
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockup
    function createWithDurationsLD(
        Lockup.CreateWithDurations calldata params,
        LockupDynamic.SegmentWithDuration[] calldata segmentsWithDuration
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Use the block timestamp as the start time.
        uint40 startTime = uint40(block.timestamp);

        // Generate the canonical segments.
        LockupDynamic.Segment[] memory segments = Helpers.calculateSegmentTimestamps(segmentsWithDuration, startTime);

        // Declare the timestamps for the stream.
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: startTime, end: segments[segments.length - 1].timestamp });

        // Checks, Effects and Interactions: create the stream.
        streamId = _createLD(
            Lockup.CreateWithTimestamps({
                sender: params.sender,
                recipient: params.recipient,
                totalAmount: params.totalAmount,
                token: params.token,
                cancelable: params.cancelable,
                transferable: params.transferable,
                timestamps: timestamps,
                shape: params.shape,
                broker: params.broker
            }),
            segments
        );
    }

    /// @inheritdoc ISablierLockup
    function createWithDurationsLL(
        Lockup.CreateWithDurations calldata params,
        LockupLinear.UnlockAmounts calldata unlockAmounts,
        LockupLinear.Durations calldata durations
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Set the current block timestamp as the stream's start time.
        Lockup.Timestamps memory timestamps = Lockup.Timestamps({ start: uint40(block.timestamp), end: 0 });

        uint40 cliffTime;

        // Calculate the cliff time and the end time.
        if (durations.cliff > 0) {
            cliffTime = timestamps.start + durations.cliff;
        }
        timestamps.end = timestamps.start + durations.total;

        // Checks, Effects and Interactions: create the stream.
        streamId = _createLL(
            Lockup.CreateWithTimestamps({
                sender: params.sender,
                recipient: params.recipient,
                totalAmount: params.totalAmount,
                token: params.token,
                cancelable: params.cancelable,
                transferable: params.transferable,
                timestamps: timestamps,
                shape: params.shape,
                broker: params.broker
            }),
            unlockAmounts,
            cliffTime
        );
    }

    /// @inheritdoc ISablierLockup
    function createWithDurationsLT(
        Lockup.CreateWithDurations calldata params,
        LockupTranched.TrancheWithDuration[] calldata tranchesWithDuration
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Use the block timestamp as the start time.
        uint40 startTime = uint40(block.timestamp);

        // Generate the canonical tranches.
        LockupTranched.Tranche[] memory tranches = Helpers.calculateTrancheTimestamps(tranchesWithDuration, startTime);

        // Declare the timestamps for the stream.
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: startTime, end: tranches[tranches.length - 1].timestamp });

        // Checks, Effects and Interactions: create the stream.
        streamId = _createLT(
            Lockup.CreateWithTimestamps({
                sender: params.sender,
                recipient: params.recipient,
                totalAmount: params.totalAmount,
                token: params.token,
                cancelable: params.cancelable,
                transferable: params.transferable,
                timestamps: timestamps,
                shape: params.shape,
                broker: params.broker
            }),
            tranches
        );
    }

    /// @inheritdoc ISablierLockup
    function createWithTimestampsLD(
        Lockup.CreateWithTimestamps calldata params,
        LockupDynamic.Segment[] calldata segments
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _createLD(params, segments);
    }

    /// @inheritdoc ISablierLockup
    function createWithTimestampsLL(
        Lockup.CreateWithTimestamps calldata params,
        LockupLinear.UnlockAmounts calldata unlockAmounts,
        uint40 cliffTime
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _createLL(params, unlockAmounts, cliffTime);
    }

    /// @inheritdoc ISablierLockup
    function createWithTimestampsLT(
        Lockup.CreateWithTimestamps calldata params,
        LockupTranched.Tranche[] calldata tranches
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _createLT(params, tranches);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierLockupBase
    function _calculateStreamedAmount(uint256 streamId) internal view override returns (uint128) {
        // Load in memory the parameters used in {VestingMath}.
        uint40 blockTimestamp = uint40(block.timestamp);
        uint128 depositedAmount = _streams[streamId].amounts.deposited;
        Lockup.Model lockupModel = _streams[streamId].lockupModel;
        uint128 streamedAmount;
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: _streams[streamId].startTime, end: _streams[streamId].endTime });

        // Calculate the streamed amount for the Lockup Dynamic model.
        if (lockupModel == Lockup.Model.LOCKUP_DYNAMIC) {
            streamedAmount = VestingMath.calculateLockupDynamicStreamedAmount({
                depositedAmount: depositedAmount,
                segments: _segments[streamId],
                blockTimestamp: blockTimestamp,
                timestamps: timestamps,
                withdrawnAmount: _streams[streamId].amounts.withdrawn
            });
        }
        // Calculate the streamed amount for the Lockup Linear model.
        else if (lockupModel == Lockup.Model.LOCKUP_LINEAR) {
            streamedAmount = VestingMath.calculateLockupLinearStreamedAmount({
                depositedAmount: depositedAmount,
                blockTimestamp: blockTimestamp,
                timestamps: timestamps,
                cliffTime: _cliffs[streamId],
                unlockAmounts: _unlockAmounts[streamId],
                withdrawnAmount: _streams[streamId].amounts.withdrawn
            });
        }
        // Calculate the streamed amount for the Lockup Tranched model.
        else if (lockupModel == Lockup.Model.LOCKUP_TRANCHED) {
            streamedAmount = VestingMath.calculateLockupTranchedStreamedAmount({
                depositedAmount: depositedAmount,
                blockTimestamp: blockTimestamp,
                timestamps: timestamps,
                tranches: _tranches[streamId]
            });
        }

        return streamedAmount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Common logic for creating a stream.
    /// @return The common parameters emitted in the create event between all Lockup models.
    function _create(
        uint256 streamId,
        Lockup.CreateWithTimestamps memory params,
        Lockup.CreateAmounts memory createAmounts,
        Lockup.Model lockupModel
    )
        internal
        returns (Lockup.CreateEventCommon memory)
    {
        // Effect: create the stream.
        _streams[streamId] = Lockup.Stream({
            sender: params.sender,
            startTime: params.timestamps.start,
            endTime: params.timestamps.end,
            isCancelable: params.cancelable,
            wasCanceled: false,
            token: params.token,
            isDepleted: false,
            isStream: true,
            isTransferable: params.transferable,
            lockupModel: lockupModel,
            amounts: Lockup.Amounts({ deposited: createAmounts.deposit, withdrawn: 0, refunded: 0 })
        });

        // Effect: mint the NFT to the recipient.
        _mint({ to: params.recipient, tokenId: streamId });

        unchecked {
            // Effect: bump the next stream ID.
            nextStreamId = streamId + 1;
        }

        // Interaction: transfer the deposit amount.
        params.token.safeTransferFrom({ from: msg.sender, to: address(this), value: createAmounts.deposit });

        // Interaction: pay the broker fee, if not zero.
        if (createAmounts.brokerFee > 0) {
            params.token.safeTransferFrom({ from: msg.sender, to: params.broker.account, value: createAmounts.brokerFee });
        }

        return Lockup.CreateEventCommon({
            funder: msg.sender,
            sender: params.sender,
            recipient: params.recipient,
            amounts: createAmounts,
            token: params.token,
            cancelable: params.cancelable,
            transferable: params.transferable,
            timestamps: params.timestamps,
            shape: params.shape,
            broker: params.broker.account
        });
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _createLD(
        Lockup.CreateWithTimestamps memory params,
        LockupDynamic.Segment[] memory segments
    )
        internal
        returns (uint256 streamId)
    {
        // Check: validate the user-provided parameters and segments.
        Lockup.CreateAmounts memory createAmounts = Helpers.checkCreateLockupDynamic({
            sender: params.sender,
            timestamps: params.timestamps,
            totalAmount: params.totalAmount,
            segments: segments,
            maxCount: MAX_COUNT,
            brokerFee: params.broker.fee,
            shape: params.shape,
            maxBrokerFee: MAX_BROKER_FEE
        });

        // Load the stream ID in a variable.
        streamId = nextStreamId;

        // Effect: store the segments. Since Solidity lacks a syntax for copying arrays of structs directly from
        // memory to storage, a manual approach is necessary. See https://github.com/ethereum/solidity/issues/12783.
        uint256 segmentCount = segments.length;
        for (uint256 i = 0; i < segmentCount; ++i) {
            _segments[streamId].push(segments[i]);
        }

        // Effect: create the stream,  mint the NFT and transfer the deposit amount.
        Lockup.CreateEventCommon memory commonParams = _create({
            streamId: streamId,
            params: params,
            createAmounts: createAmounts,
            lockupModel: Lockup.Model.LOCKUP_DYNAMIC
        });

        // Log the newly created stream.
        emit ISablierLockup.CreateLockupDynamicStream({
            streamId: streamId,
            commonParams: commonParams,
            segments: segments
        });
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _createLL(
        Lockup.CreateWithTimestamps memory params,
        LockupLinear.UnlockAmounts memory unlockAmounts,
        uint40 cliffTime
    )
        internal
        returns (uint256 streamId)
    {
        // Check: validate the user-provided parameters and cliff time.
        Lockup.CreateAmounts memory createAmounts = Helpers.checkCreateLockupLinear({
            sender: params.sender,
            timestamps: params.timestamps,
            cliffTime: cliffTime,
            totalAmount: params.totalAmount,
            unlockAmounts: unlockAmounts,
            brokerFee: params.broker.fee,
            shape: params.shape,
            maxBrokerFee: MAX_BROKER_FEE
        });

        // Load the stream ID in a variable.
        streamId = nextStreamId;

        // Effect: set the start unlock amount if it is non-zero.
        if (unlockAmounts.start > 0) {
            _unlockAmounts[streamId].start = unlockAmounts.start;
        }

        // Effect: update cliff time if it is non-zero.
        if (cliffTime > 0) {
            _cliffs[streamId] = cliffTime;

            // Effect: set the cliff unlock amount if it is non-zero.
            if (unlockAmounts.cliff > 0) {
                _unlockAmounts[streamId].cliff = unlockAmounts.cliff;
            }
        }

        // Effect: create the stream,  mint the NFT and transfer the deposit amount.
        Lockup.CreateEventCommon memory commonParams = _create({
            streamId: streamId,
            params: params,
            createAmounts: createAmounts,
            lockupModel: Lockup.Model.LOCKUP_LINEAR
        });

        // Log the newly created stream.
        emit ISablierLockup.CreateLockupLinearStream({
            streamId: streamId,
            commonParams: commonParams,
            cliffTime: cliffTime,
            unlockAmounts: unlockAmounts
        });
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _createLT(
        Lockup.CreateWithTimestamps memory params,
        LockupTranched.Tranche[] memory tranches
    )
        internal
        returns (uint256 streamId)
    {
        // Check: validate the user-provided parameters and tranches.
        Lockup.CreateAmounts memory createAmounts = Helpers.checkCreateLockupTranched({
            sender: params.sender,
            timestamps: params.timestamps,
            totalAmount: params.totalAmount,
            tranches: tranches,
            maxCount: MAX_COUNT,
            brokerFee: params.broker.fee,
            shape: params.shape,
            maxBrokerFee: MAX_BROKER_FEE
        });

        // Load the stream ID in a variable.
        streamId = nextStreamId;

        // Effect: store the tranches. Since Solidity lacks a syntax for copying arrays of structs directly from
        // memory to storage, a manual approach is necessary. See https://github.com/ethereum/solidity/issues/12783.
        uint256 trancheCount = tranches.length;
        for (uint256 i = 0; i < trancheCount; ++i) {
            _tranches[streamId].push(tranches[i]);
        }

        // Effect: create the stream,  mint the NFT and transfer the deposit amount.
        Lockup.CreateEventCommon memory commonParams = _create({
            streamId: streamId,
            params: params,
            createAmounts: createAmounts,
            lockupModel: Lockup.Model.LOCKUP_TRANCHED
        });

        // Log the newly created stream.
        emit ISablierLockup.CreateLockupTranchedStream({
            streamId: streamId,
            commonParams: commonParams,
            tranches: tranches
        });
    }
}
