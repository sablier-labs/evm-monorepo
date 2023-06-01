// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { LockupDynamic_Fork_Test } from "../LockupDynamic.t.sol";
import { LockupLinear_Fork_Test } from "../LockupLinear.t.sol";

/// @dev A typical 18-decimal ERC-20 asset with a normal total supply.
IERC20 constant asset = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
address constant holder = 0x66F62574ab04989737228D18C3624f7FC1edAe14;

contract DAI_LockupDynamic_Fork_Test is LockupDynamic_Fork_Test(asset, holder) { }

contract DAI_LockupLinear_Fork_Test is LockupLinear_Fork_Test(asset, holder) { }
