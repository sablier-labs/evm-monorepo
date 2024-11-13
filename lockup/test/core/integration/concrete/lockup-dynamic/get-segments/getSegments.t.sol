pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";
import { LockupDynamic } from "src/core/types/DataTypes.sol";

import { Lockup_Dynamic_Integration_Shared_Test } from "./../LockupDynamic.t.sol";

contract GetSegments_Integration_Concrete_Test is Lockup_Dynamic_Integration_Shared_Test {
    function test_RevertGiven_Null() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));
        lockup.getSegments(nullStreamId);
    }

    function test_GivenNotNull() external {
        LockupDynamic.Segment[] memory actualSegments = lockup.getSegments(defaultStreamId);
        LockupDynamic.Segment[] memory expectedSegments = defaults.segments();
        assertEq(actualSegments, expectedSegments, "segments");
    }
}
