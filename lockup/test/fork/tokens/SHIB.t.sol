// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Linear_Fork_Test } from "../lockup/linear/Linear.t.sol";
import { Pro_Fork_Test } from "../lockup/pro/Pro.t.sol";

/// @dev An ERC-20 asset with a large total supply.
IERC20 constant asset = IERC20(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);
address constant holder = 0x73AF3bcf944a6559933396c1577B257e2054D935;

contract SHIB_Linear_Fork_Test is Linear_Fork_Test(asset, holder) {}

contract SHIB_Pro_Fork_Test is Pro_Fork_Test(asset, holder) {}
