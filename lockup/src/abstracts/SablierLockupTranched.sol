// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { NoDelegateCall } from "@sablier/evm-utils/src/NoDelegateCall.sol";

import { ISablierLockupTranched } from "../interfaces/ISablierLockupTranched.sol";
import { Helpers } from "../libraries/Helpers.sol";
import { Lockup } from "../types/Lockup.sol";
import { LockupTranched } from "../types/LockupTranched.sol";
import { SablierLockupState } from "./SablierLockupState.sol";

/// @title SablierLockupTranched
/// @notice See the documentation in {ISablierLockupTranched}.
abstract contract SablierLockupTranched is
    ISablierLockupTranched, // 1 inherited component
    NoDelegateCall, // 0 inherited components
    SablierLockupState // 1 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockupTranched
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

    /// @inheritdoc ISablierLockupTranched
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
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this private function.
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
        private
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
        emit ISablierLockupTranched.CreateLockupTranchedStream({
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
