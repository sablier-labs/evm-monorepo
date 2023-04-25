// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Dynamic_Fork_Test } from "../lockup-dynamic/Dynamic.t.sol";
import { Linear_Fork_Test } from "../lockup-linear/Linear.t.sol";

/// @dev An ERC-20 asset with 2 decimals.
IERC20 constant asset = IERC20(0xdB25f211AB05b1c97D595516F45794528a807ad8);
address constant holder = 0x9712c160925403A9458BfC6bBD7D8a1E694C984a;

contract EURS_Dynamic_Fork_Test is Dynamic_Fork_Test(asset, holder) { }

contract EURS_Linear_Fork_Test is Linear_Fork_Test(asset, holder) { }
