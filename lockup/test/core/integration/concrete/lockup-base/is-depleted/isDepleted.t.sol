// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract IsDepleted_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));
        lockup.isDepleted(nullStreamId);
    }

    function test_GivenNotDepletedStream() external view givenNotNull {
        bool isDepleted = lockup.isDepleted(defaultStreamId);
        assertFalse(isDepleted, "isDepleted");
    }

    function test_GivenDepletedStream() external givenNotNull {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        bool isDepleted = lockup.isDepleted(defaultStreamId);
        assertTrue(isDepleted, "isDepleted");
    }
}
