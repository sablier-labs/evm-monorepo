// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2LockupDynamic } from "src/SablierV2LockupDynamic.sol";

import { LockupDynamic_Integration_Concrete_Test } from "./LockupDynamic.t.sol";

contract Constructor_LockupDynamic_Integration_Concrete_Test is LockupDynamic_Integration_Concrete_Test {
    function test_Constructor() external {
        // Expect the relevant event to be emitted.
        vm.expectEmit();
        emit TransferAdmin({ oldAdmin: address(0), newAdmin: users.admin });

        // Construct the contract.
        SablierV2LockupDynamic constructedLockupDynamic = new SablierV2LockupDynamic({
            initialAdmin: users.admin,
            initialComptroller: comptroller,
            initialNFTDescriptor: nftDescriptor,
            maxSegmentCount: defaults.MAX_SEGMENT_COUNT()
        });

        // {SablierV2Base.constructor}
        address actualAdmin = constructedLockupDynamic.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        address actualComptroller = address(constructedLockupDynamic.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");

        // {SablierV2Lockup.constructor}
        uint256 actualStreamId = constructedLockupDynamic.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");

        // {SablierV2LockupDynamic.constructor}
        uint256 actualMaxSegmentCount = constructedLockupDynamic.MAX_SEGMENT_COUNT();
        uint256 expectedMaxSegmentCount = defaults.MAX_SEGMENT_COUNT();
        assertEq(actualMaxSegmentCount, expectedMaxSegmentCount, "MAX_SEGMENT_COUNT");
    }
}
