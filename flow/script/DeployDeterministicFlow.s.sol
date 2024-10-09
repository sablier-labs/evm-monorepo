// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { FlowNFTDescriptor } from "src/FlowNFTDescriptor.sol";
import { FlowNFTDescriptor } from "src/FlowNFTDescriptor.sol";
import { SablierFlow } from "src/SablierFlow.sol";
import { DeploymentLogger } from "./DeploymentLogger.s.sol";

/// @notice Deploys {SablierFlow} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicFlow is DeploymentLogger("deterministic") {
    function run() public returns (SablierFlow flow, FlowNFTDescriptor nftDescriptor) {
        (flow, nftDescriptor) = _run(adminMap[block.chainid]);
    }

    function run(address initialAdmin) public returns (SablierFlow flow, FlowNFTDescriptor nftDescriptor) {
        (flow, nftDescriptor) = _run(initialAdmin);
    }

    function _run(address initialAdmin) public broadcast returns (SablierFlow flow, FlowNFTDescriptor nftDescriptor) {
        bytes32 salt = constructCreate2Salt();
        nftDescriptor = new FlowNFTDescriptor{ salt: salt }();
        flow = new SablierFlow{ salt: salt }(initialAdmin, nftDescriptor);

        appendToFileDeployedAddresses(address(flow), address(nftDescriptor));
    }
}
