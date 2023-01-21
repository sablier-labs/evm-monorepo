// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { Linear_Integration_Test } from "test/integration/lockup/linear/Linear.t.sol";
import { Pro_Integration_Test } from "test/integration/lockup/pro/Pro.t.sol";

/// @dev An ERC-20 asset with 6 decimals.
IERC20 constant asset = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
address constant holder = 0x09528d637deb5857dc059dddE6316D465a8b3b69;

contract USDC_Pro_Integration_Test is Pro_Integration_Test(asset, holder) {}

contract USDC_Linear_Integration_Test is Linear_Integration_Test(asset, holder) {}
