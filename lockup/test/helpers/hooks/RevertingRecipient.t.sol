// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2Recipient } from "src/hooks/ISablierV2Recipient.sol";

contract RevertingRecipient is ISablierV2Recipient {
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
        revert("You shall not pass");
    }

    function onStreamWithdrawn(uint256 streamId, address caller, uint128 withdrawAmount) external pure {
        streamId;
        caller;
        withdrawAmount;
        revert("You shall not pass");
    }
}
