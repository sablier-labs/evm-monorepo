// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { ISablierV2LockupSender } from "../../../src/interfaces/hooks/ISablierV2LockupSender.sol";

contract GoodSender is ISablierV2LockupSender {
    function onStreamCanceled(
        uint256 streamId,
        address recipient,
        uint128 senderAmount,
        uint128 recipientAmount
    )
        external
        pure
    {
        streamId;
        recipient;
        senderAmount;
        recipientAmount;
    }
}
