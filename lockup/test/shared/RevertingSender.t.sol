// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2Sender } from "src/interfaces/ISablierV2Sender.sol";

contract RevertingSender is ISablierV2Sender {
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
}
