// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierFlow } from "src/SablierFlow.sol";
import { SablierFlowNFTDescriptor } from "src/SablierFlowNFTDescriptor.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys {SablierFlow} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicFlow is BaseScript {
    function run(address initialAdmin)
        public
        broadcast
        returns (SablierFlow flow, SablierFlowNFTDescriptor nftDescriptor)
    {
        bytes32 salt = constructCreate2Salt();
        nftDescriptor = new SablierFlowNFTDescriptor{ salt: salt }();
        flow = new SablierFlow{ salt: salt }(initialAdmin, nftDescriptor);
    }
}
