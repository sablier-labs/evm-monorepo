// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__UnitTest__GetSegmentAmounts is SablierV2ProUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testGetSegmentAmounts__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256[] memory actualSegmentAmounts = sablierV2Pro.getSegmentAmounts(nonStreamId);
        uint256[] memory expectedSegmentAmounts;
        assertEq(actualSegmentAmounts, expectedSegmentAmounts);
    }

    /// @dev When the stream exists, it should return the correct segment amounts.
    function testGetSegmentAmounts() external {
        uint256 daiStreamId = createDefaultDaiStream();
        uint256[] memory actualSegmentAmounts = sablierV2Pro.getSegmentAmounts(daiStreamId);
        uint256[] memory expectedSegmentAmounts = daiStream.segmentAmounts;
        assertEq(actualSegmentAmounts, expectedSegmentAmounts);
    }
}
