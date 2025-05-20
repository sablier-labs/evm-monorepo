// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IAdminable } from "@sablier/evm-utils/src/interfaces/IAdminable.sol";

import { SablierFlow } from "src/SablierFlow.sol";

import { Shared_Integration_Concrete_Test } from "./Concrete.t.sol";

contract Constructor_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function test_Constructor() external {
        // Expect the relevant event to be emitted.
        vm.expectEmit();
        emit IAdminable.TransferAdmin({ oldAdmin: address(0), newAdmin: users.admin });

        // Construct the contract.
        SablierFlow constructedFlow = new SablierFlow(users.admin, address(nftDescriptor));

        // {SablierFlowState.nextStreamId}
        uint256 actualStreamId = constructedFlow.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");

        // {Adminable.constructor}
        address actualAdmin = constructedFlow.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        // {SablierFlowState.supportsInterface}
        assertTrue(constructedFlow.supportsInterface(0x49064906), "ERC-4906 interface ID");

        address actualNFTDescriptor = address(constructedFlow.nftDescriptor());
        address expectedNFTDescriptor = address(nftDescriptor);
        assertEq(actualNFTDescriptor, expectedNFTDescriptor, "nftDescriptor");
    }
}
