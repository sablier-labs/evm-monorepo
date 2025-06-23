// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { SablierFlow } from "../../src/SablierFlow.sol";

/// @notice Deploys {SablierFlow}.
contract DeployFlow is BaseScript {
    function run(address nftDescriptor) public broadcast returns (SablierFlow flow) {
        flow = new SablierFlow(getComptroller(), nftDescriptor);
    }
}
