// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Escrow_Fork_Test } from "../Escrow.t.sol";

/// @dev An ERC-20 token with 6 decimals paired with an 18-decimal wrapped native token.
IERC20 constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
IERC20 constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

contract USDC_WETH_Escrow_Fork_Test is Escrow_Fork_Test(usdc, weth) { }
