// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Escrow_Fork_Test } from "../Escrow.t.sol";

/// @dev An ERC-20 token that suffers from the missing return value bug paired with a typical 18-decimal token.
IERC20 constant usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
IERC20 constant dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

contract USDT_DAI_Escrow_Fork_Test is Escrow_Fork_Test(usdt, dai) { }
