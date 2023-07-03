// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2NFTDescriptor } from "../src/SablierV2NFTDescriptor.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev Deploys {SablierV2NFTDescriptor} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicNFTDescriptor is BaseScript {
    /// @dev The presence of the salt instructs Forge to deploy contracts via this deterministic CREATE2 factory:
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(string memory create2Salt) public virtual broadcast returns (SablierV2NFTDescriptor nftDescriptor) {
        nftDescriptor = new SablierV2NFTDescriptor{ salt: bytes32(abi.encodePacked(create2Salt)) }();
    }
}
