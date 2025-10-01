// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { FlowNFTDescriptor } from "../../src/FlowNFTDescriptor.sol";

contract DeployFlowNFTDescriptor is BaseScript {
    function run() public broadcast returns (FlowNFTDescriptor nftDescriptor) {
        nftDescriptor = new FlowNFTDescriptor();
    }
}
