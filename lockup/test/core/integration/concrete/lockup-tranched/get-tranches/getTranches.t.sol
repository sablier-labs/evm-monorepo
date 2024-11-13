// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";
import { LockupTranched } from "src/core/types/DataTypes.sol";

import { Lockup_Tranched_Integration_Shared_Test } from "../LockupTranched.t.sol";

contract GetTranches_Integration_Concrete_Test is Lockup_Tranched_Integration_Shared_Test {
    function test_RevertGiven_Null() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));
        lockup.getTranches(nullStreamId);
    }

    function test_GivenNotNull() external {
        LockupTranched.Tranche[] memory actualTranches = lockup.getTranches(defaultStreamId);
        LockupTranched.Tranche[] memory expectedTranches = defaults.tranches();
        assertEq(actualTranches, expectedTranches, "tranches");
    }
}
