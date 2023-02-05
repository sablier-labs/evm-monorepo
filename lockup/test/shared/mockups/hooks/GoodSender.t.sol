// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { ISablierV2LockupSender } from "src/interfaces/hooks/ISablierV2LockupSender.sol";

contract GoodSender is ISablierV2LockupSender {
    function onStreamCanceled(uint256 streamId, uint128 senderAmount, uint128 recipientAmount) external pure {
        streamId;
        senderAmount;
        recipientAmount;
    }
}
