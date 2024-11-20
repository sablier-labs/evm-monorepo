// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";
import { BatchLockup } from "src/core/types/DataTypes.sol";

import { Base_Test } from "test/Base.t.sol";

contract CreateWithDurationsLL_Integration_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        resetPrank({ msgSender: users.sender });
    }

    function test_RevertWhen_BatchSizeZero() external {
        BatchLockup.CreateWithDurationsLL[] memory batchParams = new BatchLockup.CreateWithDurationsLL[](0);
        vm.expectRevert(Errors.SablierBatchLockup_BatchSizeZero.selector);
        batchLockup.createWithDurationsLL(lockup, dai, batchParams);
    }

    function test_WhenBatchSizeNotZero() external {
        // Asset flow: Sender → batchLockup → SablierLockup
        // Expect transfers from Alice to the batchLockup, and then from the batchLockup to the Lockup contract.
        expectCallToTransferFrom({
            from: users.sender,
            to: address(batchLockup),
            value: defaults.TOTAL_TRANSFER_AMOUNT()
        });

        expectMultipleCallsToCreateWithDurationsLL({
            count: defaults.BATCH_SIZE(),
            params: defaults.createWithDurationsBrokerNull(),
            unlockAmounts: defaults.unlockAmounts(),
            durations: defaults.durations()
        });
        expectMultipleCallsToTransferFrom({
            count: defaults.BATCH_SIZE(),
            from: address(batchLockup),
            to: address(lockup),
            value: defaults.DEPOSIT_AMOUNT()
        });

        // Assert that the batch of streams has been created successfully.
        uint256[] memory actualStreamIds =
            batchLockup.createWithDurationsLL(lockup, dai, defaults.batchCreateWithDurationsLL());
        uint256[] memory expectedStreamIds = defaults.incrementalStreamIds();
        assertEq(actualStreamIds, expectedStreamIds, "stream ids mismatch");
    }
}
