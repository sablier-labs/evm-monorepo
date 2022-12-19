// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";
import { ISablierV2Recipient } from "src/interfaces/ISablierV2Recipient.sol";

contract ReentrantRecipient is ISablierV2Recipient {
    function onStreamCanceled(
        uint256 streamId,
        address caller,
        uint128 withdrawAmount,
        uint128 returnAmount
    ) external {
        streamId;
        caller;
        withdrawAmount;
        returnAmount;
        ISablierV2(msg.sender).cancel(streamId);
    }

    function onStreamWithdrawn(
        uint256 streamId,
        address caller,
        uint128 withdrawAmount
    ) external {
        streamId;
        caller;
        withdrawAmount;
        ISablierV2(msg.sender).withdraw(streamId, address(this), withdrawAmount);
    }
}
