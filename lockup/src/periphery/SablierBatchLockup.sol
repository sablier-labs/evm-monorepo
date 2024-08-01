// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISablierLockupDynamic } from "../core/interfaces/ISablierLockupDynamic.sol";
import { ISablierLockupLinear } from "../core/interfaces/ISablierLockupLinear.sol";
import { ISablierLockupTranched } from "../core/interfaces/ISablierLockupTranched.sol";
import { LockupDynamic, LockupLinear, LockupTranched } from "../core/types/DataTypes.sol";

import { ISablierBatchLockup } from "./interfaces/ISablierBatchLockup.sol";
import { Errors } from "./libraries/Errors.sol";
import { BatchLockup } from "./types/DataTypes.sol";

/// @title SablierBatchLockup
/// @notice See the documentation in {ISablierBatchLockup}.
contract SablierBatchLockup is ISablierBatchLockup {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-LOCKUP-DYNAMIC
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierBatchLockup
    function createWithDurationsLD(
        ISablierLockupDynamic lockupDynamic,
        IERC20 asset,
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
                transferAmount += batch[i].totalAmount;
            }
        }

        // Perform the ERC-20 transfer and approve {SablierLockupDynamic} to spend the amount of assets.
        _handleTransfer(address(lockupDynamic), asset, transferAmount);

        // Create a stream for each element in the parameter array.
        streamIds = new uint256[](batchSize);
        for (i = 0; i < batchSize; ++i) {
            // Create the stream.
            streamIds[i] = lockupDynamic.createWithDurations(
                LockupDynamic.CreateWithDurations({
                    sender: batch[i].sender,
                    recipient: batch[i].recipient,
                    totalAmount: batch[i].totalAmount,
                    asset: asset,
                    cancelable: batch[i].cancelable,
                    transferable: batch[i].transferable,
                    segments: batch[i].segments,
                    broker: batch[i].broker
                })
            );
        }
    }

    /// @inheritdoc ISablierBatchLockup
    function createWithTimestampsLD(
        ISablierLockupDynamic lockupDynamic,
        IERC20 asset,
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
                transferAmount += batch[i].totalAmount;
            }
        }

        // Perform the ERC-20 transfer and approve {SablierLockupDynamic} to spend the amount of assets.
        _handleTransfer(address(lockupDynamic), asset, transferAmount);

        // Create a stream for each element in the parameter array.
        streamIds = new uint256[](batchSize);
        for (i = 0; i < batchSize; ++i) {
            // Create the stream.
            streamIds[i] = lockupDynamic.createWithTimestamps(
                LockupDynamic.CreateWithTimestamps({
                    sender: batch[i].sender,
                    recipient: batch[i].recipient,
                    totalAmount: batch[i].totalAmount,
                    asset: asset,
                    cancelable: batch[i].cancelable,
                    transferable: batch[i].transferable,
                    startTime: batch[i].startTime,
                    segments: batch[i].segments,
                    broker: batch[i].broker
                })
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-LOCKUP-LINEAR
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierBatchLockup
    function createWithDurationsLL(
        ISablierLockupLinear lockupLinear,
        IERC20 asset,
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
                transferAmount += batch[i].totalAmount;
            }
        }

        // Perform the ERC-20 transfer and approve {SablierLockupLinear} to spend the amount of assets.
        _handleTransfer(address(lockupLinear), asset, transferAmount);

        // Create a stream for each element in the parameter array.
        streamIds = new uint256[](batchSize);
        for (i = 0; i < batchSize; ++i) {
            // Create the stream.
            streamIds[i] = lockupLinear.createWithDurations(
                LockupLinear.CreateWithDurations({
                    sender: batch[i].sender,
                    recipient: batch[i].recipient,
                    totalAmount: batch[i].totalAmount,
                    asset: asset,
                    cancelable: batch[i].cancelable,
                    transferable: batch[i].transferable,
                    durations: batch[i].durations,
                    broker: batch[i].broker
                })
            );
        }
    }

    /// @inheritdoc ISablierBatchLockup
    function createWithTimestampsLL(
        ISablierLockupLinear lockupLinear,
        IERC20 asset,
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
                transferAmount += batch[i].totalAmount;
            }
        }

        // Perform the ERC-20 transfer and approve {SablierLockupLinear} to spend the amount of assets.
        _handleTransfer(address(lockupLinear), asset, transferAmount);

        // Create a stream for each element in the parameter array.
        streamIds = new uint256[](batchSize);
        for (i = 0; i < batchSize; ++i) {
            // Create the stream.
            streamIds[i] = lockupLinear.createWithTimestamps(
                LockupLinear.CreateWithTimestamps({
                    sender: batch[i].sender,
                    recipient: batch[i].recipient,
                    totalAmount: batch[i].totalAmount,
                    asset: asset,
                    cancelable: batch[i].cancelable,
                    transferable: batch[i].transferable,
                    timestamps: batch[i].timestamps,
                    broker: batch[i].broker
                })
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                              SABLIER-LOCKUP-TRANCHED
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierBatchLockup
    function createWithDurationsLT(
        ISablierLockupTranched lockupTranched,
        IERC20 asset,
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
                transferAmount += batch[i].totalAmount;
            }
        }

        // Perform the ERC-20 transfer and approve {SablierLockupTranched} to spend the amount of assets.
        _handleTransfer(address(lockupTranched), asset, transferAmount);

        // Create a stream for each element in the parameter array.
        streamIds = new uint256[](batchSize);
        for (i = 0; i < batchSize; ++i) {
            // Create the stream.
            streamIds[i] = lockupTranched.createWithDurations(
                LockupTranched.CreateWithDurations({
                    sender: batch[i].sender,
                    recipient: batch[i].recipient,
                    totalAmount: batch[i].totalAmount,
                    asset: asset,
                    cancelable: batch[i].cancelable,
                    transferable: batch[i].transferable,
                    tranches: batch[i].tranches,
                    broker: batch[i].broker
                })
            );
        }
    }

    /// @inheritdoc ISablierBatchLockup
    function createWithTimestampsLT(
        ISablierLockupTranched lockupTranched,
        IERC20 asset,
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
                transferAmount += batch[i].totalAmount;
            }
        }

        // Perform the ERC-20 transfer and approve {SablierLockupTranched} to spend the amount of assets.
        _handleTransfer(address(lockupTranched), asset, transferAmount);

        // Create a stream for each element in the parameter array.
        streamIds = new uint256[](batchSize);
        for (i = 0; i < batchSize; ++i) {
            // Create the stream.
            streamIds[i] = lockupTranched.createWithTimestamps(
                LockupTranched.CreateWithTimestamps({
                    sender: batch[i].sender,
                    recipient: batch[i].recipient,
                    totalAmount: batch[i].totalAmount,
                    asset: asset,
                    cancelable: batch[i].cancelable,
                    transferable: batch[i].transferable,
                    startTime: batch[i].startTime,
                    tranches: batch[i].tranches,
                    broker: batch[i].broker
                })
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to approve a Lockup contract to spend funds from the batchLockup. If the current allowance
    /// is insufficient, this function approves Lockup to spend the exact `amount`.
    /// The {SafeERC20.forceApprove} function is used to handle special ERC-20 assets (e.g. USDT) that require the
    /// current allowance to be zero before setting it to a non-zero value.
    function _approve(address lockupContract, IERC20 asset, uint256 amount) internal {
        uint256 allowance = asset.allowance({ owner: address(this), spender: lockupContract });
        if (allowance < amount) {
            asset.forceApprove({ spender: lockupContract, value: amount });
        }
    }

    /// @dev Helper function to transfer assets from the caller to the batchLockup contract and approve the Lockup
    /// contract.
    function _handleTransfer(address lockupContract, IERC20 asset, uint256 amount) internal {
        // Transfer the assets to the batchLockup contract.
        asset.safeTransferFrom({ from: msg.sender, to: address(this), value: amount });

        // Approve the Lockup contract to spend funds.
        _approve(lockupContract, asset, amount);
    }
}
