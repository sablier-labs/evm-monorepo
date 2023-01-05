// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2Recipient } from "src/interfaces/hooks/ISablierV2Recipient.sol";

contract RevertingRecipient is ISablierV2Recipient {
    function onStreamCanceled(
        uint256 streamId,
        address caller,
        uint128 recipientAmount,
        uint128 senderAmount
    ) external pure {
        streamId;
        caller;
        recipientAmount;
        senderAmount;
        revert("You shall not pass");
    }

    function onStreamWithdrawn(uint256 streamId, address caller, uint128 amount) external pure {
        streamId;
        caller;
        amount;
        revert("You shall not pass");
    }
}
