// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2Recipient } from "src/interfaces/ISablierV2Recipient.sol";

contract NonRevertingRecipient is ISablierV2Recipient {
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
    }

    function onStreamWithdrawn(uint256 streamId, address caller, uint128 withdrawAmount) external pure {
        streamId;
        caller;
        withdrawAmount;
    }
}
