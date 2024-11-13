// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./../../shared/lockup/Lockup.t.sol";

/// @dev A shared test used across Lockup Tranched concrete and fuzz tests.
abstract contract Lockup_Tranched_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    function setUp() public virtual override {
        Lockup_Integration_Shared_Test.setUp();

        // Initialize streams IDs.
        defaultStreamId = createDefaultStreamLT();
        cancelMultipleStreamIds = WarpAndCreateStreamsForCancelMultipleLT({ warpTime: getBlockTimestamp() });
        differentSenderRecipientStreamId =
            createDefaultStreamWithUsersLT({ recipient: address(recipientGood), sender: users.sender });
        earlyEndtimeStreamId = createDefaultStreamWithEndTimeLT({ endTime: defaults.CLIFF_TIME() + 1 seconds });
        identicalSenderRecipientStreamId = createDefaultStreamWithIdenticalUsersLT(users.sender);
        notCancelableStreamId = createDefaultStreamNotCancelableLT();
        notTransferableStreamId = createDefaultStreamNotTransferableLT();
        recipientGoodStreamId = createDefaultStreamWithRecipientLT(address(recipientGood));
        recipientInvalidSelectorStreamId = createDefaultStreamWithRecipientLT(address(recipientInvalidSelector));
        recipientReentrantStreamId = createDefaultStreamWithRecipientLT(address(recipientReentrant));
        recipientRevertStreamId = createDefaultStreamWithRecipientLT(address(recipientReverting));
        withdrawMultipleStreamIds = WarpAndCreateStreamsWithdrawMultipleLT({ warpTime: getBlockTimestamp() });
    }
}
