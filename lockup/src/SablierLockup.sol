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
import { LockupMath } from "./libraries/LockupMath.sol";
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

    /// @dev Cliff timestamp mapped by stream IDs, used in LL streams.
    mapping(uint256 streamId => uint40 cliffTime) internal _cliffs;

    /// @dev Stream segments mapped by stream IDs, used in LD streams.
    mapping(uint256 streamId => LockupDynamic.Segment[] segments) internal _segments;

    /// @dev Stream tranches mapped by stream IDs, used in LT streams.
    mapping(uint256 streamId => LockupTranched.Tranche[] tranches) internal _tranches;

    /// @dev Unlock amounts mapped by stream IDs, used in LL streams.
    mapping(uint256 streamId => LockupLinear.UnlockAmounts unlockAmounts) internal _unlockAmounts;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialNFTDescriptor The address of the NFT descriptor contract.
    constructor(
        address initialAdmin,
        ILockupNFTDescriptor initialNFTDescriptor
    )
        ERC721("Sablier Lockup NFT", "SAB-LOCKUP")
        SablierLockupBase(initialAdmin, initialNFTDescriptor)
    {
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
        streamId = _createLD({
            cancelable: params.cancelable,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            segments: segments,
            sender: params.sender,
            shape: params.shape,
            timestamps: timestamps,
            token: params.token,
            transferable: params.transferable
        });
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
        streamId = _createLL({
            cancelable: params.cancelable,
            cliffTime: cliffTime,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            sender: params.sender,
            shape: params.shape,
            timestamps: timestamps,
            token: params.token,
            transferable: params.transferable,
            unlockAmounts: unlockAmounts
        });
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
        streamId = _createLT({
            cancelable: params.cancelable,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            sender: params.sender,
            shape: params.shape,
            timestamps: timestamps,
            token: params.token,
            tranches: tranches,
            transferable: params.transferable
        });
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
        streamId = _createLD({
            cancelable: params.cancelable,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            segments: segments,
            sender: params.sender,
            shape: params.shape,
            timestamps: params.timestamps,
            token: params.token,
            transferable: params.transferable
        });
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
        streamId = _createLL({
            cancelable: params.cancelable,
            cliffTime: cliffTime,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            sender: params.sender,
            shape: params.shape,
            timestamps: params.timestamps,
            token: params.token,
            transferable: params.transferable,
            unlockAmounts: unlockAmounts
        });
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
        streamId = _createLT({
            cancelable: params.cancelable,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            sender: params.sender,
            shape: params.shape,
            timestamps: params.timestamps,
            token: params.token,
            tranches: tranches,
            transferable: params.transferable
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierLockupBase
    function _streamedAmountOf(uint256 streamId) internal view override returns (uint128 streamedAmount) {
        // Load the stream from storage.
        Lockup.Stream memory stream = _streams[streamId];

        if (stream.isDepleted) {
            return stream.amounts.withdrawn;
        } else if (stream.wasCanceled) {
            return stream.amounts.deposited - stream.amounts.refunded;
        }

        // Calculate the streamed amount for the LD model.
        if (stream.lockupModel == Lockup.Model.LOCKUP_DYNAMIC) {
            streamedAmount = LockupMath.calculateStreamedAmountLD({
                depositedAmount: stream.amounts.deposited,
                endTime: stream.endTime,
                segments: _segments[streamId],
                startTime: stream.startTime,
                withdrawnAmount: stream.amounts.withdrawn
            });
        }
        // Calculate the streamed amount for the LL model.
        else if (stream.lockupModel == Lockup.Model.LOCKUP_LINEAR) {
            streamedAmount = LockupMath.calculateStreamedAmountLL({
                cliffTime: _cliffs[streamId],
                depositedAmount: stream.amounts.deposited,
                endTime: stream.endTime,
                startTime: stream.startTime,
                unlockAmounts: _unlockAmounts[streamId],
                withdrawnAmount: stream.amounts.withdrawn
            });
        }
        // Calculate the streamed amount for the LT model.
        else if (stream.lockupModel == Lockup.Model.LOCKUP_TRANCHED) {
            streamedAmount = LockupMath.calculateStreamedAmountLT({
                depositedAmount: stream.amounts.deposited,
                endTime: stream.endTime,
                startTime: stream.startTime,
                tranches: _tranches[streamId]
            });
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Common logic for creating a stream.
    function _create(
        bool cancelable,
        uint128 depositAmount,
        Lockup.Model lockupModel,
        address recipient,
        Lockup.Timestamps memory timestamps,
        IERC20 token,
        bool transferable,
        address sender,
        uint256 streamId
    )
        internal
    {
        // Effect: create the stream.
        _streams[streamId] = Lockup.Stream({
            sender: sender,
            startTime: timestamps.start,
            endTime: timestamps.end,
            isCancelable: cancelable,
            wasCanceled: false,
            token: token,
            isDepleted: false,
            isTransferable: transferable,
            lockupModel: lockupModel,
            amounts: Lockup.Amounts({ deposited: depositAmount, withdrawn: 0, refunded: 0 })
        });

        // Effect: mint the NFT to the recipient.
        _mint({ to: recipient, tokenId: streamId });

        unchecked {
            // Effect: bump the next stream ID.
            nextStreamId = streamId + 1;

            // Effect: increase the aggregate amount.
            aggregateAmount[token] += depositAmount;
        }

        // Interaction: transfer the deposit amount.
        token.safeTransferFrom({ from: msg.sender, to: address(this), value: depositAmount });
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _createLD(
        bool cancelable,
        uint128 depositAmount,
        address recipient,
        LockupDynamic.Segment[] memory segments,
        address sender,
        string memory shape,
        Lockup.Timestamps memory timestamps,
        IERC20 token,
        bool transferable
    )
        internal
        returns (uint256 streamId)
    {
        // Check: validate the user-provided parameters and segments.
        Helpers.checkCreateLD({
            sender: sender,
            timestamps: timestamps,
            depositAmount: depositAmount,
            segments: segments,
            token: address(token),
            nativeToken: nativeToken,
            shape: shape
        });

        // Load the stream ID in a variable.
        streamId = nextStreamId;

        // Effect: store the segments. Since Solidity lacks a syntax for copying arrays of structs directly from
        // memory to storage, a manual approach is necessary. See https://github.com/ethereum/solidity/issues/12783.
        uint256 segmentCount = segments.length;
        for (uint256 i = 0; i < segmentCount; ++i) {
            _segments[streamId].push(segments[i]);
        }

        // Effect: create the stream, mint the NFT and transfer the deposit amount.
        _create({
            cancelable: cancelable,
            depositAmount: depositAmount,
            lockupModel: Lockup.Model.LOCKUP_DYNAMIC,
            recipient: recipient,
            sender: sender,
            streamId: streamId,
            timestamps: timestamps,
            token: token,
            transferable: transferable
        });

        // Log the newly created stream.
        emit ISablierLockup.CreateLockupDynamicStream({
            streamId: streamId,
            commonParams: Lockup.CreateEventCommon({
                sender: sender,
                recipient: recipient,
                depositAmount: depositAmount,
                token: token,
                cancelable: cancelable,
                transferable: transferable,
                timestamps: timestamps,
                shape: shape
            }),
            segments: segments
        });
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _createLL(
        bool cancelable,
        uint40 cliffTime,
        uint128 depositAmount,
        address recipient,
        address sender,
        string memory shape,
        Lockup.Timestamps memory timestamps,
        IERC20 token,
        bool transferable,
        LockupLinear.UnlockAmounts memory unlockAmounts
    )
        internal
        returns (uint256 streamId)
    {
        // Check: validate the user-provided parameters and cliff time.
        Helpers.checkCreateLL({
            sender: sender,
            timestamps: timestamps,
            cliffTime: cliffTime,
            depositAmount: depositAmount,
            unlockAmounts: unlockAmounts,
            token: address(token),
            nativeToken: nativeToken,
            shape: shape
        });

        // Load the stream ID in a variable.
        streamId = nextStreamId;

        // Effect: set the start and cliff unlock amounts.
        _unlockAmounts[streamId] = unlockAmounts;

        // Effect: update cliff time.
        _cliffs[streamId] = cliffTime;

        // Effect: create the stream, mint the NFT and transfer the deposit amount.
        _create({
            cancelable: cancelable,
            depositAmount: depositAmount,
            lockupModel: Lockup.Model.LOCKUP_LINEAR,
            recipient: recipient,
            sender: sender,
            streamId: streamId,
            timestamps: timestamps,
            token: token,
            transferable: transferable
        });

        // Log the newly created stream.
        emit ISablierLockup.CreateLockupLinearStream({
            streamId: streamId,
            commonParams: Lockup.CreateEventCommon({
                sender: sender,
                recipient: recipient,
                depositAmount: depositAmount,
                token: token,
                cancelable: cancelable,
                transferable: transferable,
                timestamps: timestamps,
                shape: shape
            }),
            cliffTime: cliffTime,
            unlockAmounts: unlockAmounts
        });
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _createLT(
        bool cancelable,
        uint128 depositAmount,
        address recipient,
        address sender,
        string memory shape,
        Lockup.Timestamps memory timestamps,
        IERC20 token,
        bool transferable,
        LockupTranched.Tranche[] memory tranches
    )
        internal
        returns (uint256 streamId)
    {
        // Check: validate the user-provided parameters and tranches.
        Helpers.checkCreateLT({
            sender: sender,
            timestamps: timestamps,
            depositAmount: depositAmount,
            tranches: tranches,
            token: address(token),
            nativeToken: nativeToken,
            shape: shape
        });

        // Load the stream ID in a variable.
        streamId = nextStreamId;

        // Effect: store the tranches. Since Solidity lacks a syntax for copying arrays of structs directly from
        // memory to storage, a manual approach is necessary. See https://github.com/ethereum/solidity/issues/12783.
        uint256 trancheCount = tranches.length;
        for (uint256 i = 0; i < trancheCount; ++i) {
            _tranches[streamId].push(tranches[i]);
        }

        // Effect: create the stream, mint the NFT and transfer the deposit amount.
        _create({
            cancelable: cancelable,
            depositAmount: depositAmount,
            lockupModel: Lockup.Model.LOCKUP_TRANCHED,
            recipient: recipient,
            sender: sender,
            streamId: streamId,
            timestamps: timestamps,
            token: token,
            transferable: transferable
        });

        // Log the newly created stream.
        emit ISablierLockup.CreateLockupTranchedStream({
            streamId: streamId,
            commonParams: Lockup.CreateEventCommon({
                sender: sender,
                recipient: recipient,
                depositAmount: depositAmount,
                token: token,
                cancelable: cancelable,
                transferable: transferable,
                timestamps: timestamps,
                shape: shape
            }),
            tranches: tranches
        });
    }
}
