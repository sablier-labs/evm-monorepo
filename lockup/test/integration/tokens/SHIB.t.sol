// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { CreateWithMilestones__Test } from "../create/createWithMilestones.t.sol";
import { CreateWithRange__Test } from "../create/createWithRange.t.sol";

/// @dev A token with a large total supply.
IERC20 constant token = IERC20(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);
address constant holder = 0x73AF3bcf944a6559933396c1577B257e2054D935;

contract SHIB__CreateWithMilestones__Test is CreateWithMilestones__Test(token, holder) {}

contract SHIB__CreateWithRange__Test is CreateWithRange__Test(token, holder) {}
