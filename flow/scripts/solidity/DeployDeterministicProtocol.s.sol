// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { FlowNFTDescriptor } from "../../src/FlowNFTDescriptor.sol";
import { SablierFlow } from "../../src/SablierFlow.sol";

import { NFTDescriptorAddresses } from "./NFTDescriptorAddresses.sol";

/// @notice Deploys the protocol at a deterministic addresses across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicFlow is BaseScript, NFTDescriptorAddresses {
    function run() public broadcast returns (SablierFlow flow, address nftDescriptor) {
        address initialAdmin = protocolAdmin();
        bytes32 salt = constructCreate2Salt();

        // If the contract is not already, deploy it.
        if (nftDescriptorAddress() == address(0)) {
            nftDescriptor = address(new FlowNFTDescriptor{ salt: salt }());
        }
        // Otherwise, use the address of the existing contract.
        else {
            nftDescriptor = nftDescriptorAddress();
        }

        flow = new SablierFlow{ salt: salt }(initialAdmin, nftDescriptor);
    }
}
