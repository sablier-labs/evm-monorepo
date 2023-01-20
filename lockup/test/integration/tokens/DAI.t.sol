// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { Linear_Integration_Test } from "test/integration/lockup/linear/Linear.t.sol";
import { Pro_Integration_Test } from "test/integration/lockup/pro/Pro.t.sol";

/// @dev A typical 18-decimal ERC-20 asset with a normal total supply.
IERC20 constant asset = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
address constant holder = 0x66F62574ab04989737228D18C3624f7FC1edAe14;

contract DAI_Linear_Test is Linear_Integration_Test(asset, holder) {}

contract DAI_Pro_Test is Pro_Integration_Test(asset, holder) {}
