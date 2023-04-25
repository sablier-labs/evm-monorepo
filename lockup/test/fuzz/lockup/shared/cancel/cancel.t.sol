// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../../Fuzz.t.sol";

abstract contract Cancel_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        defaultStreamId = createDefaultStream();
        changePrank({ msgSender: users.recipient });
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenNotNull() {
        _;
    }

    modifier whenStreamWarm() {
        _;
    }

    modifier whenCallerAuthorized() {
        _;
    }

    modifier whenStreamCancelable() {
        _;
    }

    function testFuzz_Cancel_StatusPending(uint256 timeWarp)
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
    {
        timeWarp = bound(timeWarp, 1 seconds, 100 weeks);

        // Warp into the past.
        vm.warp({ timestamp: getBlockTimestamp() - timeWarp });

        // Cancel the stream.
        lockup.cancel(defaultStreamId);

        // Assert that the stream's status is depleted.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    modifier whenStatusStreaming() {
        _;
    }

    modifier whenCallerSender() {
        changePrank({ msgSender: users.sender });
        _;
    }

    modifier whenRecipientContract() {
        _;
    }

    modifier whenRecipientImplementsHook() {
        _;
    }

    modifier whenRecipientDoesNotRevert() {
        _;
    }

    modifier whenNoRecipientReentrancy() {
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the current time
    /// - With and without withdrawals
    function testFuzz_Cancel_CallerSender(
        uint256 timeWarp,
        uint128 withdrawAmount
    )
        external
        whenNoDelegateCall
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
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Create the stream.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the withdraw amount.
        uint128 streamedAmount = lockup.streamedAmountOf(streamId);
        withdrawAmount = boundUint128(withdrawAmount, 0, streamedAmount - 1);

        // Make the withdrawal only if the amount is greater than zero.
        if (withdrawAmount > 0) {
            lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });
        }

        // Expect the assets to be refunded to the sender.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        expectTransferCall({ to: users.sender, amount: senderAmount });

        // Expect a {CancelLockupStream} event to be emitted.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream(streamId, users.sender, address(goodRecipient), senderAmount, recipientAmount);

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is canceled.
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

    modifier whenCallerRecipient() {
        _;
    }

    modifier whenSenderContract() {
        _;
    }

    modifier whenSenderImplementsHook() {
        _;
    }

    modifier whenSenderDoesNotRevert() {
        _;
    }

    modifier whenNoSenderReentrancy() {
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the current time
    /// - With and without withdrawals
    function testFuzz_Cancel_CallerRecipient(
        uint256 timeWarp,
        uint128 withdrawAmount
    )
        external
        whenNoDelegateCall
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
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Create the stream.
        uint256 streamId = createDefaultStreamWithSender(address(goodSender));

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the withdraw amount.
        uint128 streamedAmount = lockup.streamedAmountOf(streamId);
        withdrawAmount = boundUint128(withdrawAmount, 0, streamedAmount - 1);

        // Make the withdrawal only if the amount is greater than zero.
        if (withdrawAmount > 0) {
            lockup.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });
        }

        // Expect the assets to be refunded to the sender.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        expectTransferCall({ to: address(goodSender), amount: senderAmount });

        // Expect a {CancelLockupStream} event to be emitted.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream(streamId, address(goodSender), users.recipient, senderAmount, recipientAmount);

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is canceled.
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
