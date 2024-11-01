// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract IsWarm_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Null.selector, nullStreamId));
        lockup.isWarm(nullStreamId);
    }

    function test_GivenPENDINGStatus() external givenNotNull {
        vm.warp({ newTimestamp: getBlockTimestamp() - 1 seconds });
        bool isWarm = lockup.isWarm(defaultStreamId);
        assertTrue(isWarm, "isWarm");
    }

    function test_GivenSTREAMINGStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        bool isWarm = lockup.isWarm(defaultStreamId);
        assertTrue(isWarm, "isWarm");
    }

    function test_GivenSETTLEDStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        bool isWarm = lockup.isWarm(defaultStreamId);
        assertFalse(isWarm, "isWarm");
    }

    function test_GivenCANCELEDStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);
        bool isWarm = lockup.isWarm(defaultStreamId);
        assertFalse(isWarm, "isWarm");
    }

    function test_GivenDEPLETEDStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        bool isWarm = lockup.isWarm(defaultStreamId);
        assertFalse(isWarm, "isWarm");
    }
}
