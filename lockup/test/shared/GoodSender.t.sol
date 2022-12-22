// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2Sender } from "src/hooks/ISablierV2Sender.sol";

contract GoodSender is ISablierV2Sender {
    function onStreamCanceled(
        uint256 streamId,
        address caller,
        uint128 withdrawAmount,
        uint128 returnAmount
    ) external pure {
        streamId;
        caller;
        withdrawAmount;
        returnAmount;
    }
}
