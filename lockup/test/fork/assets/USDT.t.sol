// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Dynamic_Fork_Test } from "../lockup/dynamic/Dynamic.t.sol";
import { Linear_Fork_Test } from "../lockup/linear/Linear.t.sol";

/// @dev An ERC-20 asset that has the missing return value bug.
IERC20 constant asset = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
address constant holder = 0xee5B5B923fFcE93A870B3104b7CA09c3db80047A;

contract USDT_Dynamic_Fork_Test is Dynamic_Fork_Test(asset, holder) { }

contract USDT_Linear_Fork_Test is Linear_Fork_Test(asset, holder) { }
