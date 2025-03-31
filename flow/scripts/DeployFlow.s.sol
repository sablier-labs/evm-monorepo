// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { IFlowNFTDescriptor } from "src/interfaces/IFlowNFTDescriptor.sol";
import { SablierFlow } from "src/SablierFlow.sol";

/// @notice Deploys {SablierFlow}.
contract DeployFlow is BaseScript {
    function run(IFlowNFTDescriptor nftDescriptor) public broadcast returns (SablierFlow flow) {
        address initialAdmin = protocolAdmin();
        flow = new SablierFlow(initialAdmin, nftDescriptor);
    }
}
