// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Precompiles } from "precompiles/Precompiles.sol";
import { LibString } from "solady/src/utils/LibString.sol";

import { ILockupNFTDescriptor } from "src/core/interfaces/ILockupNFTDescriptor.sol";
import { ISablierBatchLockup } from "src/core/interfaces/ISablierBatchLockup.sol";
import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { ISablierMerkleFactory } from "src/periphery/interfaces/ISablierMerkleFactory.sol";

import { Base_Test } from "./../Base.t.sol";

contract Precompiles_Test is Base_Test {
    using LibString for address;

    Precompiles internal precompiles = new Precompiles();

    modifier onlyTestOptimizedProfile() {
        if (isTestOptimizedProfile()) {
            _;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        CORE
    //////////////////////////////////////////////////////////////////////////*/

    function test_DeployBatchLockup() external onlyTestOptimizedProfile {
        address actualBatchLockup = address(precompiles.deployBatchLockup());
        address expectedBatchLockup = address(deployOptimizedBatchLockup());
        assertEq(actualBatchLockup.code, expectedBatchLockup.code, "bytecodes mismatch");
    }

    function test_DeployLockup() external onlyTestOptimizedProfile {
        address actualLockup = address(precompiles.deployLockup(users.admin, nftDescriptor));
        address expectedLockup = address(deployOptimizedLockup(users.admin, nftDescriptor, precompiles.MAX_COUNT()));
        bytes memory expectedLockupCode = adjustBytecode(expectedLockup.code, expectedLockup, actualLockup);
        assertEq(actualLockup.code, expectedLockupCode, "bytecodes mismatch");
    }

    function test_DeployNFTDescriptor() external onlyTestOptimizedProfile {
        address actualNFTDescriptor = address(precompiles.deployNFTDescriptor());
        address expectedNFTDescriptor = address(deployOptimizedNFTDescriptor());
        assertEq(actualNFTDescriptor.code, expectedNFTDescriptor.code, "bytecodes mismatch");
    }

    function test_DeployCore() external onlyTestOptimizedProfile {
        (ILockupNFTDescriptor actualNFTDescriptor, ISablierLockup actualLockup, ISablierBatchLockup actualBatchLockup) =
            precompiles.deployCore(users.admin);

        (
            ILockupNFTDescriptor expectedNFTDescriptor,
            ISablierLockup expectedLockup,
            ISablierBatchLockup expectedBatchLockup
        ) = deployOptimizedCore(users.admin, precompiles.MAX_COUNT());

        bytes memory expectedLockupCode =
            adjustBytecode(address(expectedLockup).code, address(expectedLockup), address(actualLockup));

        assertEq(address(actualLockup).code, expectedLockupCode, "bytecodes mismatch");
        assertEq(address(actualNFTDescriptor).code, address(expectedNFTDescriptor).code, "bytecodes mismatch");
        assertEq(address(actualBatchLockup).code, address(expectedBatchLockup).code, "bytecodes mismatch");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     PERIPHERY
    //////////////////////////////////////////////////////////////////////////*/

    function test_DeployMerkleFactory() external onlyTestOptimizedProfile {
        address actualFactory = address(precompiles.deployMerkleFactory(users.admin));
        address expectedFactory = address(deployOptimizedMerkleFactory(users.admin));
        assertEq(actualFactory.code, expectedFactory.code, "bytecodes mismatch");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The expected bytecode has to be adjusted because {SablierLockup} inherits from {NoDelegateCall}, which
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
