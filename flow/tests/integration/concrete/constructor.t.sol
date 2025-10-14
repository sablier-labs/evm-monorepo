// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IComptrollerable } from "@sablier/evm-utils/src/interfaces/IComptrollerable.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { SablierFlow } from "src/SablierFlow.sol";

import { Shared_Integration_Concrete_Test } from "./Concrete.t.sol";

contract Constructor_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function test_Constructor() external {
        // Expect the relevant event to be emitted.
        vm.expectEmit();
        emit IComptrollerable.SetComptroller({
            newComptroller: comptroller,
            oldComptroller: ISablierComptroller(address(0))
        });

        // Construct the contract.
        SablierFlow constructedFlow = new SablierFlow(address(comptroller), address(nftDescriptor));

        // {SablierFlowState.nextStreamId}
        uint256 actualStreamId = constructedFlow.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");

        // {Comptrollerable.constructor}
        address actualComptroller = address(constructedFlow.comptroller());
        assertEq(actualComptroller, address(comptroller), "comptroller");

        // {SablierFlowState.supportsInterface}
        assertTrue(constructedFlow.supportsInterface(0x49064906), "ERC-4906 interface ID");

        address actualNFTDescriptor = address(constructedFlow.nftDescriptor());
        assertEq(actualNFTDescriptor, address(nftDescriptor), "nftDescriptor");
    }
}
