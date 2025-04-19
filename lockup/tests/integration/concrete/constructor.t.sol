// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IAdminable } from "@sablier/evm-utils/src/interfaces/IAdminable.sol";
import { SablierLockup } from "src/SablierLockup.sol";

import { Integration_Test } from "../Integration.t.sol";

contract Constructor_Integration_Concrete_Test is Integration_Test {
    function test_Constructor() external {
        // Expect the relevant event to be emitted.
        vm.expectEmit();
        emit IAdminable.TransferAdmin({ oldAdmin: address(0), newAdmin: users.admin });

        // Construct the contract.
        SablierLockup constructedLockup =
            new SablierLockup({ initialAdmin: users.admin, initialNFTDescriptor: nftDescriptor });

        // {RoleAdminable.constructor}
        address actualAdmin = constructedLockup.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        // {SablierLockupBase.constructor}
        uint256 actualStreamId = constructedLockup.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");

        // {SablierLockupBase.constructor}
        address actualNFTDescriptor = address(constructedLockup.nftDescriptor());
        address expectedNFTDescriptor = address(nftDescriptor);
        assertEq(actualNFTDescriptor, expectedNFTDescriptor, "nftDescriptor");

        // {SablierLockupBase.supportsInterface}
        assertTrue(constructedLockup.supportsInterface(0x49064906), "ERC-4906 interface ID");
    }
}
