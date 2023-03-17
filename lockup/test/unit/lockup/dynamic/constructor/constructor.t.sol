// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { SablierV2LockupDynamic } from "src/SablierV2LockupDynamic.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract Constructor_Dynamic_Unit_Test is Dynamic_Unit_Test {
    /// @dev it should initialize all values correctly and emit a {TransferAdmin} event.
    function test_Constructor() external {
        // Expect a {TransferEvent} to be emitted.
        vm.expectEmit();
        emit TransferAdmin({ oldAdmin: address(0), newAdmin: users.admin });

        // Construct the dynamic contract.
        SablierV2LockupDynamic constructedDynamic = new SablierV2LockupDynamic({
            initialAdmin: users.admin,
            initialComptroller: comptroller,
            maxFee: DEFAULT_MAX_FEE,
            initialNFTDescriptor: nftDescriptor,
            maxSegmentCount: DEFAULT_MAX_SEGMENT_COUNT
        });

        // {SablierV2-constructor}
        address actualAdmin = constructedDynamic.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        address actualComptroller = address(constructedDynamic.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");

        UD60x18 actualMaxFee = constructedDynamic.MAX_FEE();
        UD60x18 expectedMaxFee = DEFAULT_MAX_FEE;
        assertEq(actualMaxFee, expectedMaxFee, "MAX_FEE");

        // {SablierV2Lockup-constructor}
        uint256 actualStreamId = constructedDynamic.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");

        // {SablierV2LockupDynamic-constructor}
        uint256 actualMaxSegmentCount = constructedDynamic.MAX_SEGMENT_COUNT();
        uint256 expectedMaxSegmentCount = DEFAULT_MAX_SEGMENT_COUNT;
        assertEq(actualMaxSegmentCount, expectedMaxSegmentCount, "MAX_SEGMENT_COUNT");
    }
}
