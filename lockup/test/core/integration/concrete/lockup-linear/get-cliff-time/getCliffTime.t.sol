// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";

import { Lockup_Linear_Integration_Shared_Test } from "../LockupLinear.t.sol";

contract GetCliffTime_Integration_Concrete_Test is Lockup_Linear_Integration_Shared_Test {
    function test_RevertGiven_Null() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));
        lockup.getCliffTime(nullStreamId);
    }

    function test_GivenNotNull() external view {
        uint40 actualCliffTime = lockup.getCliffTime(defaultStreamId);
        uint40 expectedCliffTime = defaults.CLIFF_TIME();
        assertEq(actualCliffTime, expectedCliffTime, "cliffTime");
    }
}
