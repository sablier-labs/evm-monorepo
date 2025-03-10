// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Flow_Fork_Test } from "../Flow.t.sol";

/// @dev An ERC-20 token with 6 decimals.
IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

contract USDC_Flow_Fork_Test is Flow_Fork_Test(USDC) { }
