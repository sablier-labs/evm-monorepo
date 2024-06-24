// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierV2NFTDescriptor } from "../src/SablierV2NFTDescriptor.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev Deploys {SablierV2NFTDescriptor} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicNFTDescriptor is BaseScript {
    function run() public virtual broadcast returns (SablierV2NFTDescriptor nftDescriptor) {
        bytes32 salt = constructCreate2Salt();
        nftDescriptor = new SablierV2NFTDescriptor{ salt: salt }();
    }
}
