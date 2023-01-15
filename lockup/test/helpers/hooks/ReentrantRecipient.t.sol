// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupRecipient } from "src/interfaces/hooks/ISablierV2LockupRecipient.sol";

contract ReentrantRecipient is ISablierV2LockupRecipient {
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
        ISablierV2Lockup(msg.sender).cancel(streamId);
    }

    function onStreamWithdrawn(uint256 streamId, address caller, uint128 amount) external {
        streamId;
        caller;
        amount;
        ISablierV2Lockup(msg.sender).withdraw(streamId, address(this), amount);
    }
}
