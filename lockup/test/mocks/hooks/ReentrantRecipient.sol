// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "../../../src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupRecipient } from "../../../src/interfaces/hooks/ISablierV2LockupRecipient.sol";

contract ReentrantRecipient is ISablierV2LockupRecipient {
    function onStreamCanceled(
        ISablierV2Lockup lockup,
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
        lockup.cancel(streamId);
    }

    function onStreamRenounced(ISablierV2Lockup lockup, uint256 streamId) external {
        streamId;
        lockup.renounce(streamId);
    }

    function onStreamWithdrawn(
        ISablierV2Lockup lockup,
        uint256 streamId,
        address caller,
        address to,
        uint128 amount
    )
        external
    {
        streamId;
        caller;
        to;
        amount;
        lockup.withdraw(streamId, address(this), amount);
    }
}
