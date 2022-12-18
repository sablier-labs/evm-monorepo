// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProTest } from "../SablierV2ProTest.t.sol";

contract GetSegmentMilestones__Test is SablierV2ProTest {
    /// @dev it should return zero.
    function testGetSegmentMilestones__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint40[] memory actualSegmentMilestones = sablierV2Pro.getSegmentMilestones(nonStreamId);
        uint40[] memory expectedSegmentMilestones;
        assertEqUint40Array(actualSegmentMilestones, expectedSegmentMilestones);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct segment milestones.
    function testGetSegmentMilestones() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        uint40[] memory actualSegmentMilestones = sablierV2Pro.getSegmentMilestones(daiStreamId);
        uint40[] memory expectedSegmentMilestones = daiStream.segmentMilestones;
        assertEqUint40Array(actualSegmentMilestones, expectedSegmentMilestones);
    }
}
