// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Linear_Fork_Test } from "../lockup/linear/Linear.t.sol";
import { Pro_Fork_Test } from "../lockup/pro/Pro.t.sol";

/// @dev An ERC-20 asset with 6 decimals.
IERC20 constant asset = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
address constant holder = 0x09528d637deb5857dc059dddE6316D465a8b3b69;

contract USDC_Pro_Fork_Test is Pro_Fork_Test(asset, holder) {}

contract USDC_Linear_Fork_Test is Linear_Fork_Test(asset, holder) {}
