// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupRecipient } from "src/interfaces/hooks/ISablierV2LockupRecipient.sol";

contract ReentrantRecipient is ISablierV2LockupRecipient {
    function onStreamCanceled(
        uint256 streamId,
        address caller,
        uint128 senderAmount,
        uint128 recipientAmount
    ) external {
        streamId;
        caller;
        senderAmount;
        recipientAmount;
        ISablierV2Lockup(msg.sender).cancel(streamId);
    }

    function onStreamRenounced(uint256 streamId) external {
        streamId;
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
