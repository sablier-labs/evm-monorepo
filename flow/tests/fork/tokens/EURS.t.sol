// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Flow_Fork_Test } from "../Flow.t.sol";

/// @dev An ERC-20 token with 2 decimals.
IERC20 constant EURS = IERC20(0xdB25f211AB05b1c97D595516F45794528a807ad8);

contract EURS_Flow_Fork_Test is Flow_Fork_Test(EURS) { }
