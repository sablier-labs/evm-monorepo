// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IComptrollerManager } from "@sablier/evm-utils/src/interfaces/IComptrollerManager.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { SablierLockup } from "src/SablierLockup.sol";

import { Integration_Test } from "../Integration.t.sol";

contract Constructor_Integration_Concrete_Test is Integration_Test {
    function test_Constructor() external {
        // Expect the relevant event to be emitted.
        vm.expectEmit();
        emit IComptrollerManager.SetComptroller({
            newComptroller: comptroller,
            oldComptroller: ISablierComptroller(address(0))
        });

        // Construct the contract.
        SablierLockup constructedLockup = new SablierLockup({
            initialComptroller: address(comptroller),
            initialNFTDescriptor: address(nftDescriptor)
        });

        // {ComptrollerManager.constructor}
        address actualComptroller = address(constructedLockup.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");

        // {SablierLockupState.constructor}
        uint256 actualStreamId = constructedLockup.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");

        // {SablierLockupState.constructor}
        address actualNFTDescriptor = address(constructedLockup.nftDescriptor());
        address expectedNFTDescriptor = address(nftDescriptor);
        assertEq(actualNFTDescriptor, expectedNFTDescriptor, "nftDescriptor");

        // {SablierLockup.supportsInterface}
        assertTrue(constructedLockup.supportsInterface(0x49064906), "ERC-4906 interface ID");
    }
}
