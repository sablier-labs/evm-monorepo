// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { BatchLockup } from "src/types/BatchLockup.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract CreateWithTimestampsLD_Integration_Test is Integration_Test {
    function test_RevertWhen_BatchSizeZero() external {
        BatchLockup.CreateWithTimestampsLD[] memory batchParams = new BatchLockup.CreateWithTimestampsLD[](0);
        vm.expectRevert(Errors.SablierBatchLockup_BatchSizeZero.selector);
        batchLockup.createWithTimestampsLD(lockup, dai, batchParams);
    }

    function test_WhenBatchSizeNotZero() external {
        // Token flow: Sender → batchLockup → SablierLockup
        // Expect transfers from Alice to the batchLockup, and then from the batchLockup to the Lockup contract.
        expectCallToTransferFrom({
            from: users.sender,
            to: address(batchLockup),
            value: defaults.TOTAL_TRANSFER_AMOUNT()
        });

        expectMultipleCallsToCreateWithTimestampsLD({
            count: defaults.BATCH_SIZE(),
            params: defaults.createWithTimestamps(),
            segments: defaults.segments()
        });
        expectMultipleCallsToTransferFrom({
            count: defaults.BATCH_SIZE(),
            from: address(batchLockup),
            to: address(lockup),
            value: defaults.DEPOSIT_AMOUNT()
        });

        uint256 firstStreamId = lockup.nextStreamId();

        // Assert that the batch of streams has been created successfully.
        uint256[] memory actualStreamIds =
            batchLockup.createWithTimestampsLD(lockup, dai, defaults.batchCreateWithTimestampsLD());
        uint256[] memory expectedStreamIds = defaults.incrementalStreamIds({ firstStreamId: firstStreamId });
        assertEq(actualStreamIds, expectedStreamIds, "stream ids mismatch");
    }
}
