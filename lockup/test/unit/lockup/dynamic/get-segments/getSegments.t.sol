// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract GetSegments_Dynamic_Unit_Test is Dynamic_Unit_Test {
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        dynamic.getSegments(nullStreamId);
    }

    modifier whenStreamNonNull() {
        _;
    }

    function test_GetSegments() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        LockupDynamic.Segment[] memory actualSegments = dynamic.getSegments(streamId);
        LockupDynamic.Segment[] memory expectedSegments = DEFAULT_SEGMENTS;
        assertEq(actualSegments, expectedSegments, "segments");
    }
}
