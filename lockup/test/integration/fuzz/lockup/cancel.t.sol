// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup } from "src/types/DataTypes.sol";

import { Cancel_Integration_Shared_Test } from "../../shared/lockup/cancel.t.sol";
import { Integration_Test } from "../../Integration.t.sol";

abstract contract Cancel_Integration_Fuzz_Test is Integration_Test, Cancel_Integration_Shared_Test {
    function setUp() public virtual override(Integration_Test, Cancel_Integration_Shared_Test) {
        Cancel_Integration_Shared_Test.setUp();
    }

    function testFuzz_Cancel_StatusPending(uint256 timeJump)
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
    {
        timeJump = _bound(timeJump, 1 seconds, 100 weeks);

        // Warp to the past.
        vm.warp({ timestamp: getBlockTimestamp() - timeJump });

        // Cancel the stream.
        lockup.cancel(defaultStreamId);

        // Assert that the stream's status is "DEPLETED".
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the current time
    /// - With and without withdrawals
    function testFuzz_Cancel_CallerSender(
        uint256 timeJump,
        uint128 withdrawAmount
    )
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerSender
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
        whenNoRecipientReentrancy
    {
        timeJump = _bound(timeJump, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() - 1);

        // Create the stream.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.START_TIME() + timeJump });

        // Bound the withdraw amount.
        uint128 streamedAmount = lockup.streamedAmountOf(streamId);
        withdrawAmount = boundUint128(withdrawAmount, 0, streamedAmount - 1);

        // Make the withdrawal only if the amount is greater than zero.
        if (withdrawAmount > 0) {
            lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });
        }

        // Expect the assets to be refunded to the Sender.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        expectCallToTransfer({ to: users.sender, amount: senderAmount });

        // Expect the relevant events to be emitted.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream(streamId, users.sender, address(goodRecipient), senderAmount, recipientAmount);
        vm.expectEmit({ emitter: address(lockup) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is "CANCELED".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");

        // Assert that the NFT has not been burned.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = address(goodRecipient);
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the current time
    /// - With and without withdrawals
    function testFuzz_Cancel_CallerRecipient(
        uint256 timeJump,
        uint128 withdrawAmount
    )
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerRecipient
        whenSenderContract
        whenSenderImplementsHook
        whenSenderDoesNotRevert
        whenNoSenderReentrancy
    {
        timeJump = _bound(timeJump, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() - 1);

        // Create the stream.
        uint256 streamId = createDefaultStreamWithSender(address(goodSender));

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.START_TIME() + timeJump });

        // Bound the withdraw amount.
        uint128 streamedAmount = lockup.streamedAmountOf(streamId);
        withdrawAmount = boundUint128(withdrawAmount, 0, streamedAmount - 1);

        // Make the withdrawal only if the amount is greater than zero.
        if (withdrawAmount > 0) {
            lockup.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });
        }

        // Expect the assets to be refunded to the sender contract.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        expectCallToTransfer({ to: address(goodSender), amount: senderAmount });

        // Expect the relevant event to be emitted.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream(streamId, address(goodSender), users.recipient, senderAmount, recipientAmount);

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is "CANCELED".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");

        // Assert that the NFT has not been burned.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
