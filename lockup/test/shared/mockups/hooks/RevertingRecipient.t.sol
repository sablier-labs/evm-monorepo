// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2LockupRecipient } from "../../../../src/interfaces/hooks/ISablierV2LockupRecipient.sol";

contract RevertingRecipient is ISablierV2LockupRecipient {
    function onStreamCanceled(
        uint256 streamId,
        address sender,
        uint128 senderAmount,
        uint128 recipientAmount
    )
        external
        pure
    {
        streamId;
        sender;
        senderAmount;
        recipientAmount;
        revert("You shall not pass");
    }

    function onStreamRenounced(uint256 streamId, address sender) external pure {
        streamId;
        sender;
        revert("You shall not pass");
    }

    function onStreamWithdrawn(uint256 streamId, address caller, address to, uint128 amount) external pure {
        streamId;
        caller;
        to;
        amount;
        revert("You shall not pass");
    }
}
