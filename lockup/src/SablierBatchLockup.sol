// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISablierBatchLockup } from "./interfaces/ISablierBatchLockup.sol";
import { ISablierLockup } from "./interfaces/ISablierLockup.sol";
import { Errors } from "./libraries/Errors.sol";
import { BatchLockup } from "./types/BatchLockup.sol";
import { Lockup } from "./types/Lockup.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ██████╗  █████╗ ████████╗ ██████╗██╗  ██╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║  ██║
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    ██████╔╝███████║   ██║   ██║     ███████║
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ██╔══██╗██╔══██║   ██║   ██║     ██╔══██║
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║    ██████╔╝██║  ██║   ██║   ╚██████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝

██╗      ██████╗  ██████╗██╗  ██╗██╗   ██╗██████╗
██║     ██╔═══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗
██║     ██║   ██║██║     █████╔╝ ██║   ██║██████╔╝
██║     ██║   ██║██║     ██╔═██╗ ██║   ██║██╔═══╝
███████╗╚██████╔╝╚██████╗██║  ██╗╚██████╔╝██║
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝

*/

/// @title SablierBatchLockup
/// @notice See the documentation in {ISablierBatchLockup}.
contract SablierBatchLockup is ISablierBatchLockup {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierBatchLockup
    function createWithDurationsLD(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithDurationsLD[] calldata batch
    )
        external
        override
        returns (uint256[] memory streamIds)
    {
        // Check that the batch size is not zero.
        uint256 batchSize = batch.length;
        if (batchSize == 0) {
            revert Errors.SablierBatchLockup_BatchSizeZero();
        }

        // Calculate the sum of all of stream amounts. It is safe to use unchecked addition because one of the create
        // transactions will revert if there is overflow.
        uint256 i;
        uint256 transferAmount;
        for (i = 0; i < batchSize; ++i) {
            unchecked {
                transferAmount += batch[i].depositAmount;
            }
        }

        // Perform the ERC-20 transfer and approve {SablierLockup} to spend the amount of tokens.
        _handleTransfer(address(lockup), token, transferAmount);

        // Create a stream for each element in the parameter array.
        streamIds = new uint256[](batchSize);
        for (i = 0; i < batchSize; ++i) {
            // Create the stream.
            streamIds[i] = lockup.createWithDurationsLD(
                Lockup.CreateWithDurations({
                    sender: batch[i].sender,
                    recipient: batch[i].recipient,
                    depositAmount: batch[i].depositAmount,
                    token: token,
                    cancelable: batch[i].cancelable,
                    transferable: batch[i].transferable,
                    shape: batch[i].shape
                }),
                batch[i].segmentsWithDuration
            );
        }
    }

    /// @inheritdoc ISablierBatchLockup
    function createWithTimestampsLD(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithTimestampsLD[] calldata batch
    )
        external
        override
        returns (uint256[] memory streamIds)
    {
        // Check that the batch size is not zero.
        uint256 batchSize = batch.length;
        if (batchSize == 0) {
            revert Errors.SablierBatchLockup_BatchSizeZero();
        }

        // Calculate the sum of all of stream amounts. It is safe to use unchecked addition because one of the create
        // transactions will revert if there is overflow.
        uint256 i;
        uint256 transferAmount;
        for (i = 0; i < batchSize; ++i) {
            unchecked {
                transferAmount += batch[i].depositAmount;
            }
        }

        // Perform the ERC-20 transfer and approve {SablierLockup} to spend the amount of tokens.
        _handleTransfer(address(lockup), token, transferAmount);

        uint40 endTime;

        // Create a stream for each element in the parameter array.
        streamIds = new uint256[](batchSize);
        for (i = 0; i < batchSize; ++i) {
            // Calculate the end time of the stream.
            unchecked {
                endTime = batch[i].segments[batch[i].segments.length - 1].timestamp;
            }

            // Create the stream.
            streamIds[i] = lockup.createWithTimestampsLD(
                Lockup.CreateWithTimestamps({
                    sender: batch[i].sender,
                    recipient: batch[i].recipient,
                    depositAmount: batch[i].depositAmount,
                    token: token,
                    cancelable: batch[i].cancelable,
                    transferable: batch[i].transferable,
                    timestamps: Lockup.Timestamps({ start: batch[i].startTime, end: endTime }),
                    shape: batch[i].shape
                }),
                batch[i].segments
            );
        }
    }

    /// @inheritdoc ISablierBatchLockup
    function createWithDurationsLL(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithDurationsLL[] calldata batch
    )
        external
        override
        returns (uint256[] memory streamIds)
    {
        // Check that the batch size is not zero.
        uint256 batchSize = batch.length;
        if (batchSize == 0) {
            revert Errors.SablierBatchLockup_BatchSizeZero();
        }

        // Calculate the sum of all of stream amounts. It is safe to use unchecked addition because one of the create
        // transactions will revert if there is overflow.
        uint256 i;
        uint256 transferAmount;
        for (i = 0; i < batchSize; ++i) {
            unchecked {
                transferAmount += batch[i].depositAmount;
            }
        }

        // Perform the ERC-20 transfer and approve {SablierLockup} to spend the amount of tokens.
        _handleTransfer(address(lockup), token, transferAmount);

        // Create a stream for each element in the parameter array.
        streamIds = new uint256[](batchSize);
        for (i = 0; i < batchSize; ++i) {
            // Create the stream.
            streamIds[i] = lockup.createWithDurationsLL(
                Lockup.CreateWithDurations({
                    sender: batch[i].sender,
                    recipient: batch[i].recipient,
                    depositAmount: batch[i].depositAmount,
                    token: token,
                    cancelable: batch[i].cancelable,
                    transferable: batch[i].transferable,
                    shape: batch[i].shape
                }),
                batch[i].unlockAmounts,
                batch[i].durations
            );
        }
    }

    /// @inheritdoc ISablierBatchLockup
    function createWithTimestampsLL(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithTimestampsLL[] calldata batch
    )
        external
        override
        returns (uint256[] memory streamIds)
    {
        // Check that the batch is not empty.
        uint256 batchSize = batch.length;
        if (batchSize == 0) {
            revert Errors.SablierBatchLockup_BatchSizeZero();
        }

        // Calculate the sum of all of stream amounts. It is safe to use unchecked addition because one of the create
        // transactions will revert if there is overflow.
        uint256 i;
        uint256 transferAmount;
        for (i = 0; i < batchSize; ++i) {
            unchecked {
                transferAmount += batch[i].depositAmount;
            }
        }

        // Perform the ERC-20 transfer and approve {SablierLockup} to spend the amount of tokens.
        _handleTransfer(address(lockup), token, transferAmount);

        // Create a stream for each element in the parameter array.
        streamIds = new uint256[](batchSize);
        for (i = 0; i < batchSize; ++i) {
            // Create the stream.
            streamIds[i] = lockup.createWithTimestampsLL(
                Lockup.CreateWithTimestamps({
                    sender: batch[i].sender,
                    recipient: batch[i].recipient,
                    depositAmount: batch[i].depositAmount,
                    token: token,
                    cancelable: batch[i].cancelable,
                    transferable: batch[i].transferable,
                    timestamps: batch[i].timestamps,
                    shape: batch[i].shape
                }),
                batch[i].unlockAmounts,
                batch[i].cliffTime
            );
        }
    }

    /// @inheritdoc ISablierBatchLockup
    function createWithDurationsLT(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithDurationsLT[] calldata batch
    )
        external
        override
        returns (uint256[] memory streamIds)
    {
        // Check that the batch size is not zero.
        uint256 batchSize = batch.length;
        if (batchSize == 0) {
            revert Errors.SablierBatchLockup_BatchSizeZero();
        }

        // Calculate the sum of all of stream amounts. It is safe to use unchecked addition because one of the create
        // transactions will revert if there is overflow.
        uint256 i;
        uint256 transferAmount;
        for (i = 0; i < batchSize; ++i) {
            unchecked {
                transferAmount += batch[i].depositAmount;
            }
        }

        // Perform the ERC-20 transfer and approve {SablierLockup} to spend the amount of tokens.
        _handleTransfer(address(lockup), token, transferAmount);

        // Create a stream for each element in the parameter array.
        streamIds = new uint256[](batchSize);
        for (i = 0; i < batchSize; ++i) {
            // Create the stream.
            streamIds[i] = lockup.createWithDurationsLT(
                Lockup.CreateWithDurations({
                    sender: batch[i].sender,
                    recipient: batch[i].recipient,
                    depositAmount: batch[i].depositAmount,
                    token: token,
                    cancelable: batch[i].cancelable,
                    transferable: batch[i].transferable,
                    shape: batch[i].shape
                }),
                batch[i].tranchesWithDuration
            );
        }
    }

    /// @inheritdoc ISablierBatchLockup
    function createWithTimestampsLT(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithTimestampsLT[] calldata batch
    )
        external
        override
        returns (uint256[] memory streamIds)
    {
        // Check that the batch size is not zero.
        uint256 batchSize = batch.length;
        if (batchSize == 0) {
            revert Errors.SablierBatchLockup_BatchSizeZero();
        }

        // Calculate the sum of all of stream amounts. It is safe to use unchecked addition because one of the create
        // transactions will revert if there is overflow.
        uint256 i;
        uint256 transferAmount;
        for (i = 0; i < batchSize; ++i) {
            unchecked {
                transferAmount += batch[i].depositAmount;
            }
        }

        // Perform the ERC-20 transfer and approve {SablierLockup} to spend the amount of tokens.
        _handleTransfer(address(lockup), token, transferAmount);

        uint40 endTime;

        // Create a stream for each element in the parameter array.
        streamIds = new uint256[](batchSize);
        for (i = 0; i < batchSize; ++i) {
            // Calculate the end time of the stream.
            unchecked {
                endTime = batch[i].tranches[batch[i].tranches.length - 1].timestamp;
            }

            // Create the stream.
            streamIds[i] = lockup.createWithTimestampsLT(
                Lockup.CreateWithTimestamps({
                    sender: batch[i].sender,
                    recipient: batch[i].recipient,
                    depositAmount: batch[i].depositAmount,
                    token: token,
                    cancelable: batch[i].cancelable,
                    transferable: batch[i].transferable,
                    timestamps: Lockup.Timestamps({ start: batch[i].startTime, end: endTime }),
                    shape: batch[i].shape
                }),
                batch[i].tranches
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to approve a Lockup contract to spend funds from the batchLockup. If the current allowance
    /// is insufficient, this function approves Lockup to spend the exact `amount`.
    /// The {SafeERC20.forceApprove} function is used to handle special ERC-20 tokens (e.g. USDT) that require the
    /// current allowance to be zero before setting it to a non-zero value.
    function _approve(address lockup, IERC20 token, uint256 amount) internal {
        uint256 allowance = token.allowance({ owner: address(this), spender: lockup });
        if (allowance < amount) {
            token.forceApprove({ spender: lockup, value: amount });
        }
    }

    /// @dev Helper function to transfer tokens from the caller to the batchLockup contract and approve the Lockup
    /// contract.
    function _handleTransfer(address lockup, IERC20 token, uint256 amount) internal {
        // Transfer the tokens to the batchLockup contract.
        token.safeTransferFrom({ from: msg.sender, to: address(this), value: amount });

        // Approve the Lockup contract to spend funds.
        _approve(lockup, token, amount);
    }
}
