// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { SablierV2LockupPro } from "src/SablierV2LockupPro.sol";
import { Events } from "src/libraries/Events.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract Constructor_Pro_Unit_Test is Pro_Unit_Test {
    /// @dev it should initialize all values correctly and emit a {TransferAdmin} event.
    function test_Constructor() external {
        // Expect a {TransferEvent} to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: false });
        emit Events.TransferAdmin({ oldAdmin: address(0), newAdmin: users.admin });

        // Construct the pro contract.
        SablierV2LockupPro constructedPro = new SablierV2LockupPro({
            initialAdmin: users.admin,
            initialComptroller: comptroller,
            maxFee: DEFAULT_MAX_FEE,
            maxSegmentCount: DEFAULT_MAX_SEGMENT_COUNT
        });

        // {SablierV2-constructor}
        address actualAdmin = constructedPro.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        address actualComptroller = address(constructedPro.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");

        UD60x18 actualMaxFee = constructedPro.MAX_FEE();
        UD60x18 expectedMaxFee = DEFAULT_MAX_FEE;
        assertEq(actualMaxFee, expectedMaxFee, "MAX_FEE");

        // {SablierV2Lockup-constructor}
        uint256 actualStreamId = constructedPro.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");

        // {SablierV2LockupPro-constructor}
        uint256 actualMaxSegmentCount = constructedPro.MAX_SEGMENT_COUNT();
        uint256 expectedMaxSegmentCount = DEFAULT_MAX_SEGMENT_COUNT;
        assertEq(actualMaxSegmentCount, expectedMaxSegmentCount, "MAX_SEGMENT_COUNT");
    }
}
