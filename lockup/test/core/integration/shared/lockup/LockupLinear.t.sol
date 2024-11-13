// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./../../shared/lockup/Lockup.t.sol";

/// @dev A shared test used across Lockup Linear concrete and fuzz tests.
abstract contract Lockup_Linear_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    function setUp() public virtual override {
        Lockup_Integration_Shared_Test.setUp();

        // Initialize streams IDs.
        defaultStreamId = createDefaultStreamLL();
        cancelMultipleStreamIds = WarpAndCreateStreamsForCancelMultipleLL({ warpTime: getBlockTimestamp() });
        differentSenderRecipientStreamId =
            createDefaultStreamWithUsersLL({ recipient: address(recipientGood), sender: users.sender });
        earlyEndtimeStreamId = createDefaultStreamWithEndTimeLL({ endTime: defaults.CLIFF_TIME() + 1 seconds });
        identicalSenderRecipientStreamId = createDefaultStreamWithIdenticalUsersLL(users.sender);
        notCancelableStreamId = createDefaultStreamNotCancelableLL();
        notTransferableStreamId = createDefaultStreamNotTransferableLL();
        recipientGoodStreamId = createDefaultStreamWithRecipientLL(address(recipientGood));
        recipientInvalidSelectorStreamId = createDefaultStreamWithRecipientLL(address(recipientInvalidSelector));
        recipientReentrantStreamId = createDefaultStreamWithRecipientLL(address(recipientReentrant));
        recipientRevertStreamId = createDefaultStreamWithRecipientLL(address(recipientReverting));
        withdrawMultipleStreamIds = WarpAndCreateStreamsWithdrawMultipleLL({ warpTime: getBlockTimestamp() });
    }
}
