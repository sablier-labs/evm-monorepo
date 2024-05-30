// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierFlow } from "src/SablierFlow.sol";
import { SablierFlowNFTDescriptor } from "src/SablierFlowNFTDescriptor.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys {SablierFlow}.
contract DeployFlow is BaseScript {
    function run(address initialAdmin)
        public
        broadcast
        returns (SablierFlow flow, SablierFlowNFTDescriptor nftDescriptor)
    {
        nftDescriptor = new SablierFlowNFTDescriptor();
        flow = new SablierFlow(initialAdmin, nftDescriptor);
    }
}
