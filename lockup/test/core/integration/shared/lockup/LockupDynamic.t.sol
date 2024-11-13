// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./../../shared/lockup/Lockup.t.sol";

/// @dev A shared test used across Lockup Dynamic concrete and fuzz tests.
abstract contract Lockup_Dynamic_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    function setUp() public virtual override {
        Lockup_Integration_Shared_Test.setUp();

        // Initialize streams IDs.
        defaultStreamId = createDefaultStreamLD();
        cancelMultipleStreamIds = WarpAndCreateStreamsForCancelMultipleLD({ warpTime: getBlockTimestamp() });
        differentSenderRecipientStreamId =
            createDefaultStreamWithUsersLD({ recipient: address(recipientGood), sender: users.sender });
        earlyEndtimeStreamId = createDefaultStreamWithEndTimeLD({ endTime: defaults.CLIFF_TIME() + 1 seconds });
        identicalSenderRecipientStreamId = createDefaultStreamWithIdenticalUsersLD(users.sender);
        notCancelableStreamId = createDefaultStreamNotCancelableLD();
        notTransferableStreamId = createDefaultStreamNotTransferableLD();
        recipientGoodStreamId = createDefaultStreamWithRecipientLD(address(recipientGood));
        recipientInvalidSelectorStreamId = createDefaultStreamWithRecipientLD(address(recipientInvalidSelector));
        recipientReentrantStreamId = createDefaultStreamWithRecipientLD(address(recipientReentrant));
        recipientRevertStreamId = createDefaultStreamWithRecipientLD(address(recipientReverting));
        withdrawMultipleStreamIds = WarpAndCreateStreamsWithdrawMultipleLD({ warpTime: getBlockTimestamp() });
    }
}
