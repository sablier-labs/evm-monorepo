// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { NoDelegateCall } from "@sablier/evm-utils/src/NoDelegateCall.sol";

import { ISablierLockupDynamic } from "../interfaces/ISablierLockupDynamic.sol";
import { Helpers } from "../libraries/Helpers.sol";
import { Lockup } from "../types/Lockup.sol";
import { LockupDynamic } from "../types/LockupDynamic.sol";
import { SablierLockupState } from "./SablierLockupState.sol";

/// @title SablierLockupDynamic
/// @notice See the documentation in {ISablierLockupDynamic}.
abstract contract SablierLockupDynamic is
    ISablierLockupDynamic, // 1 inherited component
    NoDelegateCall, // 0 inherited components
    SablierLockupState // 1 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockupDynamic
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

    /// @inheritdoc ISablierLockupDynamic
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

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this private function.
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
        private
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
        emit ISablierLockupDynamic.CreateLockupDynamicStream({
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
}
