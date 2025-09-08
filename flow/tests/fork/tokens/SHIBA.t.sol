// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Flow_Fork_Test } from "../Flow.t.sol";

/// @dev An ERC-20 token with a large total supply.
IERC20 constant SHIBA = IERC20(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);

contract SHIBA_Flow_Fork_Test is Flow_Fork_Test(SHIBA) { }
