// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../../Fuzz.t.sol";

abstract contract Cancel_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        // Make the recipient the caller in this test suite.
        changePrank({ msgSender: users.recipient });

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier whenStreamNotActive() {
        _;
    }

    modifier whenStreamActive() {
        _;
    }

    modifier whenStreamCancelable() {
        _;
    }

    modifier whenCallerAuthorized() {
        _;
    }

    modifier whenCallerSender() {
        // Make the sender the caller in this test suite.
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

    /// @dev it should perform the ERC-20 transfers, cancel the stream, update the withdrawn amount, and emit a
    /// {CancelLockupStream} event.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Stream ongoing and ended.
    /// - With and without withdrawals.
    function testFuzz_Cancel_Sender(
        uint256 timeWarp,
        uint128 withdrawAmount
    )
        external
        whenStreamActive
        whenStreamCancelable
        whenCallerAuthorized
        whenCallerSender
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
        whenNoRecipientReentrancy
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Create the stream.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Bound the withdraw amount.
        uint128 streamedAmount = lockup.streamedAmountOf(streamId);
        withdrawAmount = boundUint128(withdrawAmount, 0, streamedAmount - 1);

        // Make the withdrawal only if the amount is greater than zero.
        if (withdrawAmount > 0) {
            lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });
        }

        // Expect the ERC-20 assets to be withdrawn to the recipient, if not zero.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        if (recipientAmount > 0) {
            expectTransferCall({ to: address(goodRecipient), amount: recipientAmount });
        }

        // Expect the ERC-20 assets to be returned to the sender, if not zero.
        uint128 senderAmount = lockup.returnableAmountOf(streamId);
        if (senderAmount > 0) {
            expectTransferCall({ to: users.sender, amount: senderAmount });
        }

        // Expect a {CancelLockupStream} event to be emitted.
        vm.expectEmit();
        emit CancelLockupStream(streamId, users.sender, address(goodRecipient), senderAmount, recipientAmount);

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been marked as canceled.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount + recipientAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

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

    /// @dev it should perform the ERC-20 transfers, cancel the stream, update the withdrawn amount, and emit a
    /// {CancelLockupStream} event.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Stream ongoing and ended.
    /// - With and without withdrawals.
    function testFuzz_Cancel_Recipient(
        uint256 timeWarp,
        uint128 withdrawAmount
    )
        external
        whenStreamActive
        whenStreamCancelable
        whenCallerAuthorized
        whenCallerRecipient
        whenSenderContract
        whenSenderImplementsHook
        whenSenderDoesNotRevert
        whenNoSenderReentrancy
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Create the stream.
        uint256 streamId = createDefaultStreamWithSender(address(goodSender));

        // Bound the withdraw amount.
        uint128 streamedAmount = lockup.streamedAmountOf(streamId);
        withdrawAmount = boundUint128(withdrawAmount, 0, streamedAmount - 1);

        // Make the withdrawal only if the amount is greater than zero.
        if (withdrawAmount > 0) {
            lockup.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });
        }

        // Expect the ERC-20 assets to be returned to the sender, if not zero.
        uint128 senderAmount = lockup.returnableAmountOf(streamId);
        if (senderAmount > 0) {
            expectTransferCall({ to: address(goodSender), amount: senderAmount });
        }

        // Expect the ERC-20 assets to be withdrawn to the recipient, if not zero.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        if (recipientAmount > 0) {
            expectTransferCall({ to: users.recipient, amount: recipientAmount });
        }

        // Expect a {CancelLockupStream} event to be emitted.
        vm.expectEmit();
        emit CancelLockupStream(streamId, address(goodSender), users.recipient, senderAmount, recipientAmount);

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been marked as canceled.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount + recipientAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the NFT has not been burned.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
