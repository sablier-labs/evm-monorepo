// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Flow_Fork_Test } from "../Flow.t.sol";

/// @dev A typical 18-decimal ERC-20 token with a normal total supply.
IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

contract DAI_Flow_Fork_Test is Flow_Fork_Test(DAI) { }
