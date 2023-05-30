// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <=0.9.0;

import { LibString } from "solady/utils/LibString.sol";

import { ISablierV2Comptroller } from "../../src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupDynamic } from "../../src/interfaces/ISablierV2LockupDynamic.sol";
import { ISablierV2LockupLinear } from "../../src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2NFTDescriptor } from "../../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2NFTDescriptor } from "../../src/SablierV2NFTDescriptor.sol";

import { Base_Test } from "../Base.t.sol";
import { Precompiles } from "./Precompiles.sol";

contract Precompiles_Test is Base_Test {
    using LibString for address;
    using LibString for string;

    Precompiles internal precompiles = new Precompiles();

    modifier onlyTestOptimizedProfile() {
        if (isTestOptimizedProfile()) {
            _;
        }
    }

    function test_DeployComptroller() external onlyTestOptimizedProfile {
        address actualComptroller = address(precompiles.deployComptroller(users.admin));
        address expectedComptroller = address(deployPrecompiledComptroller(users.admin));
        assertEq(actualComptroller.code, expectedComptroller.code, "bytecodes mismatch");
    }

    function test_DeployLockupDynamic() external onlyTestOptimizedProfile {
        ISablierV2Comptroller comptroller = precompiles.deployComptroller(users.admin);
        address actualDynamic = address(precompiles.deployLockupDynamic(users.admin, comptroller, nftDescriptor));
        address expectedDynamic = address(deployPrecompiledDynamic(users.admin, comptroller, nftDescriptor));
        bytes memory expectedDynamicCode = adjustBytecode(expectedDynamic.code, expectedDynamic, actualDynamic);
        assertEq(actualDynamic.code, expectedDynamicCode, "bytecodes mismatch");
    }

    function test_DeployLockupLinear() external onlyTestOptimizedProfile {
        ISablierV2Comptroller comptroller = precompiles.deployComptroller(users.admin);
        address actualLinear = address(precompiles.deployLockupLinear(users.admin, comptroller, nftDescriptor));
        address expectedLinear = address(deployPrecompiledLinear(users.admin, comptroller, nftDescriptor));
        bytes memory expectedLinearCode = adjustBytecode(expectedLinear.code, expectedLinear, actualLinear);
        assertEq(actualLinear.code, expectedLinearCode, "bytecodes mismatch");
    }

    function test_DeployNFTDescriptor() external onlyTestOptimizedProfile {
        address actualNFTDescriptor = address(precompiles.deployNFTDescriptor());
        address expectedNFTDescriptor = address(deployPrecompiledNFTDescriptor());
        assertEq(actualNFTDescriptor.code, expectedNFTDescriptor.code, "bytecodes mismatch");
    }

    function test_DeployCore() external onlyTestOptimizedProfile {
        (
            ISablierV2Comptroller actualComptroller,
            ISablierV2LockupDynamic actualDynamic,
            ISablierV2LockupLinear actualLinear,
            ISablierV2NFTDescriptor actualNFTDescriptor
        ) = precompiles.deployCore(users.admin);

        address expectedComptroller = address(deployPrecompiledComptroller(users.admin));
        assertEq(address(actualComptroller).code, expectedComptroller.code, "bytecodes mismatch");

        address expectedDynamic = address(deployPrecompiledDynamic(users.admin, comptroller, nftDescriptor));
        bytes memory expectedDynamicCode =
            adjustBytecode(address(expectedDynamic).code, address(expectedDynamic), address(actualDynamic));
        assertEq(address(actualDynamic).code, expectedDynamicCode, "bytecodes mismatch");

        address expectedLinear = address(deployPrecompiledLinear(users.admin, comptroller, nftDescriptor));
        bytes memory expectedLinearCode =
            adjustBytecode(address(expectedLinear).code, address(expectedLinear), address(actualLinear));
        assertEq(address(actualLinear).code, expectedLinearCode, "bytecodes mismatch");

        address expectedNFTDescriptor = address(deployPrecompiledNFTDescriptor());
        assertEq(address(actualNFTDescriptor).code, expectedNFTDescriptor.code, "bytecodes mismatch");
    }

    /// @dev The expected bytecode has to be adjusted because {SablierV2Lockup} inherits from {NoDelegateCall}, which
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
            vm.toString(bytecode).replace({
                search: expectedAddress.toHexStringNoPrefix(),
                replacement: actualAddress.toHexStringNoPrefix()
            })
        );
    }
}
