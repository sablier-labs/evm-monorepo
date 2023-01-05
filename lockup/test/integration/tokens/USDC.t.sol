// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { CreateWithMilestones__Test } from "../create/createWithMilestones.t.sol";
import { CreateWithRange__Test } from "../create/createWithRange.t.sol";

/// @dev A token with 6 decimals.
IERC20 constant token = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
address constant holder = 0x09528d637deb5857dc059dddE6316D465a8b3b69;

contract USDC__CreateWithMilestones__Test is CreateWithMilestones__Test(token, holder) {}

contract USDC__CreateWithRange__Test is CreateWithRange__Test(token, holder) {}
