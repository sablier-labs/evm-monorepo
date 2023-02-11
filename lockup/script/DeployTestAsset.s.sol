// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.18;

import { ERC20GodMode } from "@prb/contracts/token/erc20/ERC20GodMode.sol";

import { Script } from "forge-std/Script.sol";

import { Common } from "./helpers/Common.s.sol";

/// @notice Deploys a test ERC-20 token with infinite minting and burning capabilities.
contract DeployTestAsset is Script, Common {
    function run() public virtual broadcaster returns (ERC20GodMode token) {
        token = new ERC20GodMode("Test token", "TKN", 18);
    }
}
