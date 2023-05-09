// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { ISablierV2Lockup } from "../../../src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupSender } from "../../../src/interfaces/hooks/ISablierV2LockupSender.sol";

contract ReentrantSender is ISablierV2LockupSender {
    function onStreamCanceled(
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
        ISablierV2Lockup(msg.sender).cancel(streamId);
    }
}
