// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { FlowNFTDescriptor } from "src/FlowNFTDescriptor.sol";
import { SablierFlow } from "src/SablierFlow.sol";
import { BaseScript } from "./Base.s.sol";

/// @notice Deploys {SablierFlow}.
contract DeployFlow is BaseScript {
    function run(address initialAdmin) public broadcast returns (SablierFlow flow, FlowNFTDescriptor nftDescriptor) {
        nftDescriptor = new FlowNFTDescriptor();
        flow = new SablierFlow(initialAdmin, nftDescriptor);
    }
}
