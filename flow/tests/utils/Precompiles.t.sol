// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { LibString } from "solady/src/utils/LibString.sol";

import { Precompiles } from "../../precompiles/Precompiles.sol";

import { Base_Test } from "../Base.t.sol";

contract Precompiles_Test is Base_Test {
    using LibString for address;

    Precompiles internal precompiles = new Precompiles();

    modifier onlyTestOptimizedProfile() {
        if (isTestOptimizedProfile()) {
            _;
        }
    }

    function test_DeployFlow() external onlyTestOptimizedProfile {
        address actualSablierFlow = address(precompiles.deploySablierFlow(users.admin, nftDescriptor));
        address expectedSablierFlow = address(deployOptimizedSablierFlow());
        bytes memory expectedSablierFlowCode =
            adjustBytecode(expectedSablierFlow.code, expectedSablierFlow, actualSablierFlow);
        assertEq(actualSablierFlow.code, expectedSablierFlowCode, "bytecodes mismatch");
    }

    /// @dev The expected bytecode has to be adjusted because {SablierFlow} inherits from {NoDelegateCall}, which
    /// saves the contract's own address in storage.
    function adjustBytecode(
        bytes memory bytecode,
        address expectedAddress,
        address actualAddress
    )
        internal
        pure
        returns (bytes memory)
    {
        return vm.parseBytes(
            vm.replace({
                input: vm.toString(bytecode),
                from: expectedAddress.toHexStringNoPrefix(),
                to: actualAddress.toHexStringNoPrefix()
            })
        );
    }
}
