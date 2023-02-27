// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Linear_E2e_Test } from "../lockup/linear/Linear.t.sol";
import { Pro_E2e_Test } from "../lockup/pro/Pro.t.sol";

/// @dev An ERC-20 asset that has the missing return value bug.
IERC20 constant asset = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
address constant holder = 0xee5B5B923fFcE93A870B3104b7CA09c3db80047A;

contract USDT_Pro_E2e_Test is Pro_E2e_Test(asset, holder) {}

contract USDT_Linear_E2e_Test is Linear_E2e_Test(asset, holder) {}
