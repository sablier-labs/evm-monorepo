// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { IAdminable } from "src/core/interfaces/IAdminable.sol";
import { SablierLockupDynamic } from "src/core/SablierLockupDynamic.sol";

import { LockupDynamic_Integration_Shared_Test } from "./LockupDynamic.t.sol";

contract Constructor_LockupDynamic_Integration_Concrete_Test is LockupDynamic_Integration_Shared_Test {
    function test_Constructor() external {
        // Expect the relevant event to be emitted.
        vm.expectEmit();
        emit IAdminable.TransferAdmin({ oldAdmin: address(0), newAdmin: users.admin });

        // Construct the contract.
        SablierLockupDynamic constructedLockupDynamic = new SablierLockupDynamic({
            initialAdmin: users.admin,
            initialNFTDescriptor: nftDescriptor,
            maxSegmentCount: defaults.MAX_SEGMENT_COUNT()
        });

        // {SablierLockup.constant}
        UD60x18 actualMaxBrokerFee = constructedLockupDynamic.MAX_BROKER_FEE();
        UD60x18 expectedMaxBrokerFee = UD60x18.wrap(0.1e18);
        assertEq(actualMaxBrokerFee, expectedMaxBrokerFee, "MAX_BROKER_FEE");

        // {SablierLockup.constructor}
        address actualAdmin = constructedLockupDynamic.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        uint256 actualStreamId = constructedLockupDynamic.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");

        address actualNFTDescriptor = address(constructedLockupDynamic.nftDescriptor());
        address expectedNFTDescriptor = address(nftDescriptor);
        assertEq(actualNFTDescriptor, expectedNFTDescriptor, "nftDescriptor");

        // {SablierLockup.supportsInterface}
        assertTrue(constructedLockupDynamic.supportsInterface(0x49064906), "ERC-4906 interface ID");

        // {SablierLockupDynamic.constructor}
        uint256 actualMaxSegmentCount = constructedLockupDynamic.MAX_SEGMENT_COUNT();
        uint256 expectedMaxSegmentCount = defaults.MAX_SEGMENT_COUNT();
        assertEq(actualMaxSegmentCount, expectedMaxSegmentCount, "MAX_SEGMENT_COUNT");
    }
}
