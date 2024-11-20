// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";
import { BatchLockup } from "src/core/types/DataTypes.sol";

import { Base_Test } from "test/Base.t.sol";

contract CreateWithTimestampsLL_Integration_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        resetPrank({ msgSender: users.sender });
    }

    function test_RevertWhen_BatchSizeZero() external {
        BatchLockup.CreateWithTimestampsLL[] memory batchParams = new BatchLockup.CreateWithTimestampsLL[](0);
        vm.expectRevert(Errors.SablierBatchLockup_BatchSizeZero.selector);
        batchLockup.createWithTimestampsLL(lockup, dai, batchParams);
    }

    function test_WhenBatchSizeNotZero() external {
        // Asset flow: Sender → batchLockup → SablierLockup
        // Expect transfers from Alice to the batchLockup, and then from the batchLockup to the Lockup contract.
        expectCallToTransferFrom({
            from: users.sender,
            to: address(batchLockup),
            value: defaults.TOTAL_TRANSFER_AMOUNT()
        });

        expectMultipleCallsToCreateWithTimestampsLL({
            count: defaults.BATCH_SIZE(),
            params: defaults.createWithTimestampsBrokerNull(),
            unlockAmounts: defaults.unlockAmounts(),
            cliffTime: defaults.CLIFF_TIME()
        });
        expectMultipleCallsToTransferFrom({
            count: defaults.BATCH_SIZE(),
            from: address(batchLockup),
            to: address(lockup),
            value: defaults.DEPOSIT_AMOUNT()
        });

        // Assert that the batch of streams has been created successfully.
        uint256[] memory actualStreamIds =
            batchLockup.createWithTimestampsLL(lockup, dai, defaults.batchCreateWithTimestampsLL());
        uint256[] memory expectedStreamIds = defaults.incrementalStreamIds();
        assertEq(actualStreamIds, expectedStreamIds, "stream ids mismatch");
    }
}
