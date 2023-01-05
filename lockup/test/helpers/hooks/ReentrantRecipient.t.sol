// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";
import { ISablierV2Recipient } from "src/interfaces/hooks/ISablierV2Recipient.sol";

contract ReentrantRecipient is ISablierV2Recipient {
    function onStreamCanceled(
        uint256 streamId,
        address caller,
        uint128 recipientAmount,
        uint128 senderAmount
    ) external {
        streamId;
        caller;
        recipientAmount;
        senderAmount;
        ISablierV2(msg.sender).cancel(streamId);
    }

    function onStreamWithdrawn(uint256 streamId, address caller, uint128 amount) external {
        streamId;
        caller;
        amount;
        ISablierV2(msg.sender).withdraw(streamId, address(this), amount);
    }
}
