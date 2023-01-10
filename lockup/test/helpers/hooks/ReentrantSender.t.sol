// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Sender } from "src/interfaces/hooks/ISablierV2Sender.sol";
import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

contract ReentrantSender is ISablierV2Sender {
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
}
