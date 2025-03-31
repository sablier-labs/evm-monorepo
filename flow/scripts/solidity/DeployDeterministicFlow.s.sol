// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { IFlowNFTDescriptor } from "../../src/interfaces/IFlowNFTDescriptor.sol";
import { SablierFlow } from "../../src/SablierFlow.sol";

/// @notice Deploys {SablierFlow} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicFlow is BaseScript {
    function run(IFlowNFTDescriptor nftDescriptor) public broadcast returns (SablierFlow flow) {
        address initialAdmin = protocolAdmin();
        bytes32 salt = constructCreate2Salt();
        flow = new SablierFlow{ salt: salt }(initialAdmin, nftDescriptor);
    }
}
