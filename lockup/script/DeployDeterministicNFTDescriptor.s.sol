// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { LockupNFTDescriptor } from "../src/LockupNFTDescriptor.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev Deploys {LockupNFTDescriptor} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicNFTDescriptor is BaseScript {
    function run() public broadcast returns (LockupNFTDescriptor nftDescriptor) {
        nftDescriptor = new LockupNFTDescriptor{ salt: SALT }();
    }
}
