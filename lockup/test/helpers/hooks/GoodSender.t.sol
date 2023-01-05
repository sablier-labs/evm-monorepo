// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2Sender } from "src/interfaces/hooks/ISablierV2Sender.sol";

contract GoodSender is ISablierV2Sender {
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
    }
}
