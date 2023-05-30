// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Dynamic_Fork_Test } from "../lockup-dynamic/Dynamic.t.sol";
import { Linear_Fork_Test } from "../lockup-linear/Linear.t.sol";

/// @dev A typical 18-decimal ERC-20 asset with a normal total supply.
IERC20 constant asset = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
address constant holder = 0x66F62574ab04989737228D18C3624f7FC1edAe14;

contract DAI_Dynamic_Fork_Test is Dynamic_Fork_Test(asset, holder) { }

contract DAI_Linear_Fork_Test is Linear_Fork_Test(asset, holder) { }
