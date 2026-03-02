// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { NoDelegateCall } from "@sablier/evm-utils/src/NoDelegateCall.sol";

import { ISablierLockupPriceGated } from "../interfaces/ISablierLockupPriceGated.sol";
import { Errors } from "../libraries/Errors.sol";
import { LockupHelpers } from "../libraries/LockupHelpers.sol";
import { Lockup } from "../types/Lockup.sol";
import { LockupPriceGated } from "../types/LockupPriceGated.sol";
import { SablierLockupState } from "./SablierLockupState.sol";

/// @title SablierLockupPriceGated
/// @notice See the documentation in {ISablierLockupPriceGated}.
abstract contract SablierLockupPriceGated is
    ISablierLockupPriceGated, // 1 inherited component
    NoDelegateCall, // 0 inherited components
    SablierLockupState // 1 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockupPriceGated
    function createWithTimestampsLPG(
        Lockup.CreateWithTimestamps calldata params,
        LockupPriceGated.UnlockParams calldata unlockParams
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _createLPG(params, unlockParams);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _createLPG(
        Lockup.CreateWithTimestamps calldata params,
        LockupPriceGated.UnlockParams calldata unlockParams
    )
        private
        returns (uint256 streamId)
    {
        // Check: validate the user-provided parameters.
        LockupHelpers.checkCreateLPG(
            params.sender,
            params.timestamps,
            params.depositAmount,
            address(params.token),
            nativeToken,
            params.shape,
            unlockParams
        );

        // Load the stream ID in a variable.
        streamId = nextStreamId;

        // Effect: store unlock params.
        _priceGatedUnlockParams[streamId] = unlockParams;

        // Effect: create the stream, mint the NFT and transfer the deposit amount.
        _create({
            cancelable: params.cancelable,
            depositAmount: params.depositAmount,
            lockupModel: Lockup.Model.LOCKUP_PRICE_GATED,
            recipient: params.recipient,
            sender: params.sender,
            streamId: streamId,
            timestamps: params.timestamps,
            token: params.token,
            transferable: params.transferable
        });

        // Log the newly created stream.
        emit CreateLockupPriceGatedStream(streamId, unlockParams.oracle, unlockParams.targetPrice);
    }
}
