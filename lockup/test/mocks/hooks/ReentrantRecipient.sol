// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { ISablierV2Lockup } from "../../../src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupRecipient } from "../../../src/interfaces/hooks/ISablierV2LockupRecipient.sol";

contract ReentrantRecipient is ISablierV2LockupRecipient {
    function onStreamCanceled(
        uint256 streamId,
        address sender,
        uint128 senderAmount,
        uint128 recipientAmount
    )
        external
    {
        streamId;
        senderAmount;
        sender;
        recipientAmount;
        ISablierV2Lockup(msg.sender).cancel(streamId);
    }

    function onStreamRenounced(uint256 streamId) external {
        ISablierV2Lockup(msg.sender).renounce(streamId);
    }

    function onStreamWithdrawn(uint256 streamId, address caller, address to, uint128 amount) external {
        streamId;
        caller;
        to;
        amount;
        ISablierV2Lockup(msg.sender).withdraw(streamId, address(this), amount);
    }
}
