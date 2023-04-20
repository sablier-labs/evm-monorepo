// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "../../../src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupSender } from "../../../src/interfaces/hooks/ISablierV2LockupSender.sol";

contract ReentrantSender is ISablierV2LockupSender {
    function onStreamCanceled(
        ISablierV2Lockup lockup,
        uint256 streamId,
        address recipient,
        uint128 senderAmount,
        uint128 recipientAmount
    )
        external
    {
        streamId;
        senderAmount;
        recipient;
        recipientAmount;
        lockup.cancel(streamId);
    }
}
