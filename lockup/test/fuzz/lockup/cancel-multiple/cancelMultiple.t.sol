// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Solarray } from "solarray/Solarray.sol";

import { Lockup } from "src/types/DataTypes.sol";

import { Fuzz_Test } from "../../Fuzz.t.sol";
import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";

abstract contract CancelMultiple_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        changePrank({ msgSender: users.recipient });
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenArrayCountNotZero() {
        _;
    }

    modifier whenNoNull() {
        _;
    }

    modifier whenNoStatusSettled() {
        _;
    }

    modifier whenCallerAuthorizedAllStreams() {
        _;
    }

    modifier whenAllStreamsCancelable() {
        _;
    }

    function testFuzz_CancelMultiple_CallerSender(
        uint256 timeWarp,
        uint40 endTime
    )
        external
        whenNoDelegateCall
        whenArrayCountNotZero
        whenNoNull
        whenNoStatusSettled
        whenCallerAuthorizedAllStreams
        whenAllStreamsCancelable
    {
        // Make the sender the caller in this test.
        changePrank({ msgSender: users.sender });

        // Run the test.
        testFuzz_CancelMultiple(timeWarp, endTime);
    }

    function testFuzz_CancelMultiple_CallerRecipient(
        uint256 timeWarp,
        uint40 endTime
    )
        external
        whenNoDelegateCall
        whenArrayCountNotZero
        whenNoNull
        whenNoStatusSettled
        whenCallerAuthorizedAllStreams
        whenAllStreamsCancelable
    {
        // Make the recipient the caller in this test.
        changePrank({ msgSender: users.recipient });

        // Run the tests.
        testFuzz_CancelMultiple(timeWarp, endTime);
    }

    /// @dev Test logic shared between {testFuzz_CancelMultiple_CallerSender} and
    /// {testFuzz_CancelMultiple_CallerRecipient}.
    function testFuzz_CancelMultiple(uint256 timeWarp, uint40 endTime) internal {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION - 1);
        endTime = boundUint40(endTime, DEFAULT_END_TIME, DEFAULT_END_TIME + DEFAULT_TOTAL_DURATION);

        // Create a new stream with a different end time.
        uint256 streamId = createDefaultStreamWithEndTime(endTime);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Create the stream ids array.
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], streamId);

        // Expect the assets to be refunded to the sender.
        uint128 senderAmount0 = lockup.withdrawableAmountOf(streamIds[0]);
        expectTransferCall({ to: users.sender, amount: senderAmount0 });
        uint128 senderAmount1 = lockup.withdrawableAmountOf(streamIds[1]);
        expectTransferCall({ to: users.sender, amount: senderAmount1 });

        // Expect multiple events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream({
            streamId: streamIds[0],
            sender: users.sender,
            recipient: users.recipient,
            senderAmount: senderAmount0,
            recipientAmount: DEFAULT_DEPOSIT_AMOUNT - senderAmount0
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream({
            streamId: streamIds[1],
            sender: users.sender,
            recipient: users.recipient,
            senderAmount: senderAmount1,
            recipientAmount: DEFAULT_DEPOSIT_AMOUNT - senderAmount1
        });

        // Cancel the streams.
        lockup.cancelMultiple(streamIds);

        // Assert that the streams have been marked as canceled.
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(lockup.statusOf(streamIds[0]), expectedStatus, "status0");
        assertEq(lockup.statusOf(streamIds[1]), expectedStatus, "status1");

        // Assert that the streams are not cancelable anymore.
        assertFalse(lockup.isCancelable(streamIds[0]), "isCancelable0");
        assertFalse(lockup.isCancelable(streamIds[1]), "isCancelable1");

        // Assert that the refunded amounts have been updated.
        uint128 expectedReturnedAmount0 = senderAmount0;
        uint128 expectedReturnedAmount1 = senderAmount1;
        assertEq(lockup.getRefundedAmount(streamIds[0]), expectedReturnedAmount0, "refundedAmount0");
        assertEq(lockup.getRefundedAmount(streamIds[1]), expectedReturnedAmount1, "refundedAmount1");

        // Assert that the NFTs have not been burned.
        address expectedNFTOwner = users.recipient;
        assertEq(lockup.getRecipient(streamIds[0]), expectedNFTOwner, "NFT owner0");
        assertEq(lockup.getRecipient(streamIds[1]), expectedNFTOwner, "NFT owner1");
    }
}
