// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract IsCancelable_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));
        lockup.isCancelable(nullStreamId);
    }

    function test_GivenColdStream() external givenNotNull {
        vm.warp({ newTimestamp: defaults.END_TIME() }); // settled status
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    function test_GivenCancelableStream() external view givenNotNull givenWarmStream {
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertTrue(isCancelable, "isCancelable");
    }

    function test_GivenNonCancelableStream() external view givenNotNull givenWarmStream {
        bool isCancelable = lockup.isCancelable(notCancelableStreamId);
        assertFalse(isCancelable, "isCancelable");
    }
}
