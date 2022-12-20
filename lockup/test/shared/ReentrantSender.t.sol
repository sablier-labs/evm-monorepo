// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";
import { ISablierV2Sender } from "src/hooks/ISablierV2Sender.sol";

contract ReentrantSender is ISablierV2Sender {
    function onStreamCanceled(uint256 streamId, address caller, uint128 withdrawAmount, uint128 returnAmount) external {
        streamId;
        caller;
        withdrawAmount;
        returnAmount;
        ISablierV2(msg.sender).cancel(streamId);
    }
}
