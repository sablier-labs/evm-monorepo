// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract GetEndTime_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));
        lockup.getEndTime(nullStreamId);
    }

    function test_GivenNotNull() external view {
        uint40 actualEndTime = lockup.getEndTime(defaultStreamId);
        uint40 expectedEndTime = defaults.END_TIME();
        assertEq(actualEndTime, expectedEndTime, "endTime");
    }
}
