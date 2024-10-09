// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { FlowNFTDescriptor } from "src/FlowNFTDescriptor.sol";
import { FlowNFTDescriptor } from "src/FlowNFTDescriptor.sol";
import { SablierFlow } from "src/SablierFlow.sol";
import { DeploymentLogger } from "./DeploymentLogger.s.sol";

/// @notice Deploys {SablierFlow}.
contract DeployFlow is DeploymentLogger("not-deterministic") {
    function run() public returns (SablierFlow flow, FlowNFTDescriptor nftDescriptor) {
        (flow, nftDescriptor) = _run(adminMap[block.chainid]);
    }

    function run(address initialAdmin) public returns (SablierFlow flow, FlowNFTDescriptor nftDescriptor) {
        (flow, nftDescriptor) = _run(initialAdmin);
    }

    function _run(address initialAdmin)
        internal
        broadcast
        returns (SablierFlow flow, FlowNFTDescriptor nftDescriptor)
    {
        nftDescriptor = new FlowNFTDescriptor();
        flow = new SablierFlow(initialAdmin, nftDescriptor);

        appendToFileDeployedAddresses(address(flow), address(nftDescriptor));
    }
}
