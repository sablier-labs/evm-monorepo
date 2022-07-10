// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__UnitTest__GetSegmentMilestones is SablierV2ProUnitTest {
    /// @dev it should return zero.
    function testGetSegmentMilestones__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256[] memory actualSegmentMilestones = sablierV2Pro.getSegmentMilestones(nonStreamId);
        uint256[] memory expectedSegmentMilestones;
        assertEq(actualSegmentMilestones, expectedSegmentMilestones);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct segment milestones.
    function testGetSegmentMilestones() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        uint256[] memory actualSegmentMilestones = sablierV2Pro.getSegmentMilestones(daiStreamId);
        uint256[] memory expectedSegmentMilestones = daiStream.segmentMilestones;
        assertEq(actualSegmentMilestones, expectedSegmentMilestones);
    }
}
