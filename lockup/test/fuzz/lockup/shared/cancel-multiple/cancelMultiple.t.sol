// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Lockup } from "src/types/DataTypes.sol";

import { Fuzz_Test } from "../../../Fuzz.t.sol";
import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";

abstract contract CancelMultiple_Unit_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the caller in this test suite.
        changePrank({ msgSender: users.recipient });
    }

    modifier onlyNonNullStreams() {
        _;
    }

    modifier allStreamsCancelable() {
        _;
    }

    modifier callerAuthorizedAllStreams() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, cancel the streams, update the withdrawn amounts, and emit
    /// CancelLockupStream events.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All streams ended.
    /// - All streams ongoing.
    /// - Some streams ended, some streams ongoing.
    function testFuzz_CancelMultiple_Sender(
        uint256 timeWarp,
        uint40 endTime
    ) external onlyNonNullStreams allStreamsCancelable callerAuthorizedAllStreams {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION * 2);
        endTime = boundUint40(endTime, DEFAULT_CLIFF_TIME + 1, DEFAULT_END_TIME + DEFAULT_TOTAL_DURATION / 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Make the sender the caller in this test.
        changePrank({ msgSender: users.sender });

        // Create a new stream with a different end time.
        uint256 streamId = createDefaultStreamWithEndTime(endTime);

        // Create the stream ids array.
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], streamId);

        // Expect the ERC-20 assets to be returned to the sender, if not zero.
        uint128 recipientAmount0 = lockup.withdrawableAmountOf(streamIds[0]);
        if (recipientAmount0 > 0) {
            expectTransferCall({ to: users.recipient, amount: recipientAmount0 });
        }
        uint128 recipientAmount1 = lockup.withdrawableAmountOf(streamIds[1]);
        if (recipientAmount1 > 0) {
            expectTransferCall({ to: users.recipient, amount: recipientAmount1 });
        }

        // Expect the ERC-20 assets to be returned to the sender, if not zero.
        uint128 senderAmount0 = DEFAULT_DEPOSIT_AMOUNT - recipientAmount0;
        if (senderAmount0 > 0) {
            expectTransferCall({ to: users.sender, amount: senderAmount0 });
        }
        uint128 senderAmount1 = DEFAULT_DEPOSIT_AMOUNT - recipientAmount1;
        if (senderAmount1 > 0) {
            expectTransferCall({ to: users.sender, amount: senderAmount1 });
        }

        // Expect two {CancelLockupStream} events to be emitted.
        expectEmit();
        emit CancelLockupStream(streamIds[0], users.sender, users.recipient, senderAmount0, recipientAmount0);
        expectEmit();
        emit CancelLockupStream(streamIds[1], users.sender, users.recipient, senderAmount1, recipientAmount1);

        // Cancel the streams.
        lockup.cancelMultiple(streamIds);

        // Assert that the streams have been marked as canceled.
        Lockup.Status actualStatus0 = lockup.getStatus(streamIds[0]);
        Lockup.Status actualStatus1 = lockup.getStatus(streamIds[1]);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus0, expectedStatus, "status0");
        assertEq(actualStatus1, expectedStatus, "status1");

        // Assert that the withdrawn amounts have been updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(streamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(streamIds[1]);
        uint128 expectedWithdrawnAmount0 = recipientAmount0;
        uint128 expectedWithdrawnAmount1 = recipientAmount1;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0, "withdrawnAmount0");
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1, "withdrawnAmount1");

        // Assert that the NFTs have not been burned.
        address actualNFTOwner0 = lockup.ownerOf({ tokenId: streamIds[0] });
        address actualNFTOwner1 = lockup.ownerOf({ tokenId: streamIds[1] });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner0, expectedNFTOwner, "NFT owner0");
        assertEq(actualNFTOwner1, expectedNFTOwner, "NFT owner1");
    }

    /// @dev it should perform the ERC-20 transfers, cancel the streams, update the withdrawn amounts, and emit
    /// CancelLockupStream events.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All streams ended.
    /// - All streams ongoing.
    /// - Some streams ended, some streams ongoing.
    function testFuzz_CancelMultiple_Recipient(
        uint256 timeWarp,
        uint40 endTime
    ) external onlyNonNullStreams allStreamsCancelable callerAuthorizedAllStreams {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION * 2);
        endTime = boundUint40(endTime, DEFAULT_CLIFF_TIME + 1, DEFAULT_END_TIME + DEFAULT_TOTAL_DURATION / 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Make the recipient the caller in this test.
        changePrank({ msgSender: users.recipient });

        // Create a new stream with a different end time.
        uint256 streamId = createDefaultStreamWithEndTime(endTime);

        // Create the stream ids array.
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], streamId);

        // Expect the ERC-20 assets to be withdrawn to the recipient, if not zero.
        uint128 recipientAmount0 = lockup.withdrawableAmountOf(streamIds[0]);
        if (recipientAmount0 > 0) {
            expectTransferCall({ to: users.recipient, amount: recipientAmount0 });
        }
        uint128 recipientAmount1 = lockup.withdrawableAmountOf(streamIds[1]);
        if (recipientAmount1 > 0) {
            expectTransferCall({ to: users.recipient, amount: recipientAmount1 });
        }

        // Expect the ERC-20 assets to be returned to the sender, if not zero.
        uint128 senderAmount0 = DEFAULT_DEPOSIT_AMOUNT - recipientAmount0;
        if (senderAmount0 > 0) {
            expectTransferCall({ to: users.sender, amount: senderAmount0 });
        }
        uint128 senderAmount1 = DEFAULT_DEPOSIT_AMOUNT - recipientAmount1;
        if (senderAmount1 > 0) {
            expectTransferCall({ to: users.sender, amount: senderAmount1 });
        }

        // Expect two {CancelLockupStream} events to be emitted.
        expectEmit();
        emit CancelLockupStream(streamIds[0], users.sender, users.recipient, senderAmount0, recipientAmount0);
        expectEmit();
        emit CancelLockupStream(streamIds[1], users.sender, users.recipient, senderAmount1, recipientAmount1);

        // Cancel the streams.
        lockup.cancelMultiple(streamIds);

        // Assert that the streams have been marked as canceled.
        Lockup.Status actualStatus0 = lockup.getStatus(streamIds[0]);
        Lockup.Status actualStatus1 = lockup.getStatus(streamIds[1]);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus0, expectedStatus, "status0");
        assertEq(actualStatus1, expectedStatus, "status1");

        // Assert that the withdrawn amounts have been updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(streamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(streamIds[1]);
        uint128 expectedWithdrawnAmount0 = recipientAmount0;
        uint128 expectedWithdrawnAmount1 = recipientAmount1;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0, "withdrawAmount0");
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1, "withdrawAmount1");

        // Assert that the NFTs have not been burned.
        address actualNFTOwner0 = lockup.getRecipient(streamIds[0]);
        address actualNFTOwner1 = lockup.getRecipient(streamIds[1]);
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner0, expectedNFTOwner, "NFT owner0");
        assertEq(actualNFTOwner1, expectedNFTOwner, "NFT owner1");
    }
}
