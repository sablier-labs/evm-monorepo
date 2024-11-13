// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract IsCold_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));
        lockup.isCold(nullStreamId);
    }

    function test_GivenPENDINGStatus() external givenNotNull {
        vm.warp({ newTimestamp: getBlockTimestamp() - 1 seconds });
        bool isCold = lockup.isCold(defaultStreamId);
        assertFalse(isCold, "isCold");
    }

    function test_GivenSTREAMINGStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        bool isCold = lockup.isCold(defaultStreamId);
        assertFalse(isCold, "isCold");
    }

    function test_GivenSETTLEDStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        bool isCold = lockup.isCold(defaultStreamId);
        assertTrue(isCold, "isCold");
    }

    function test_GivenCANCELEDStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);
        bool isCold = lockup.isCold(defaultStreamId);
        assertTrue(isCold, "isCold");
    }

    function test_GivenDEPLETEDStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        bool isCold = lockup.isCold(defaultStreamId);
        assertTrue(isCold, "isCold");
    }
}
