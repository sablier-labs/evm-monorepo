// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup } from "src/core/types/DataTypes.sol";

import { Lockup_Tranched_Integration_Shared_Test } from "../LockupTranched.t.sol";

contract GetTimestamps_Lockup_Tranched_Integration_Concrete_Test is Lockup_Tranched_Integration_Shared_Test {
    function test_RevertGiven_Null() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));
        lockup.getTimestamps(nullStreamId);
    }

    function test_GivenNotNull() external {
        Lockup.Timestamps memory actualTimestamps = lockup.getTimestamps(defaultStreamId);
        Lockup.Timestamps memory expectedTimestamps = defaults.lockupTranchedTimestamps();
        assertEq(actualTimestamps, expectedTimestamps);
    }
}
