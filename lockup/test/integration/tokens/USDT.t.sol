// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { CreateWithMilestones__Test } from "../create/CreateWithMilestones.t.sol";
import { CreateWithRange__Test } from "../create/CreateWithRange.t.sol";

/// @dev A token that has the missing return value bug.
address constant token = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
address constant holder = 0xee5B5B923fFcE93A870B3104b7CA09c3db80047A;

contract USDT__CreateWithMilestones__Test is CreateWithMilestones__Test(token, holder) {}

contract USDT__CreateWithRange__Test is CreateWithRange__Test(token, holder) {}
