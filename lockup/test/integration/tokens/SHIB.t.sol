// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { CreateWithMilestones_Test } from "../create/createWithMilestones.t.sol";
import { CreateWithRange_Test } from "../create/createWithRange.t.sol";

/// @dev An ERC-20 asset with a large total supply.
IERC20 constant asset = IERC20(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);
address constant holder = 0x73AF3bcf944a6559933396c1577B257e2054D935;

contract SHIB_CreateWithMilestones_Test is CreateWithMilestones_Test(asset, holder) {}

contract SHIB_CreateWithRange_Test is CreateWithRange_Test(asset, holder) {}
