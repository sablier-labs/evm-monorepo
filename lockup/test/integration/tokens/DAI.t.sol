// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { CreateWithMilestones__Test } from "../create/CreateWithMilestones.t.sol";
import { CreateWithRange__Test } from "../create/CreateWithRange.t.sol";

/// @dev A typical 18-decimal token with a normal total supply.
address constant token = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
address constant holder = 0x66F62574ab04989737228D18C3624f7FC1edAe14;

contract DAI__CreateWithMilestones__Test is CreateWithMilestones__Test(token, holder) {}

contract DAI__CreateWithRange__Test is CreateWithRange__Test(token, holder) {}
