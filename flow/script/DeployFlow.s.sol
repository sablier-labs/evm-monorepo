// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { FlowNFTDescriptor } from "src/FlowNFTDescriptor.sol";
import { FlowNFTDescriptor } from "src/FlowNFTDescriptor.sol";
import { SablierFlow } from "src/SablierFlow.sol";

/// @notice Deploys {SablierFlow}.
contract DeployFlow is BaseScript {
    function run() public broadcast returns (SablierFlow flow, FlowNFTDescriptor nftDescriptor) {
        address initialAdmin = protocolAdmin();
        nftDescriptor = new FlowNFTDescriptor();
        flow = new SablierFlow(initialAdmin, nftDescriptor);
    }
}
