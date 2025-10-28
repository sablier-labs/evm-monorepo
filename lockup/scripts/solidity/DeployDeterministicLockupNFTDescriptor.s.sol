// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { LockupNFTDescriptor } from "../../src/LockupNFTDescriptor.sol";

/// @dev Deploys {LockupNFTDescriptor} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicLockupNFTDescriptor is BaseScript {
    function run() public broadcast returns (LockupNFTDescriptor nftDescriptor) {
        // Use just the version as salt as we want to deploy at the same address across all chains.
        bytes32 nftDescriptorSalt = bytes32(abi.encodePacked(getVersion()));
        nftDescriptor = new LockupNFTDescriptor{ salt: nftDescriptorSalt }();
    }
}
