// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Flow_Fork_Test } from "../Flow.t.sol";

/// @dev An ERC-20 token that suffers from the missing return value bug.
IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

contract USDT_Flow_Fork_Test is Flow_Fork_Test(USDT) { }
