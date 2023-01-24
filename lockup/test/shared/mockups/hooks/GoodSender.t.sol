// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2LockupSender } from "src/interfaces/hooks/ISablierV2LockupSender.sol";

contract GoodSender is ISablierV2LockupSender {
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
