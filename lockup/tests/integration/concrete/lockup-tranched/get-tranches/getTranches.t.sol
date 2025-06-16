// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupTranched } from "src/types/LockupTranched.sol";

import { Lockup_Tranched_Integration_Concrete_Test } from "../LockupTranched.t.sol";

contract GetTranches_Integration_Concrete_Test is Lockup_Tranched_Integration_Concrete_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null({ callData: abi.encodeCall(lockup.getTranches, ids.nullStream) });
    }

    function test_RevertGiven_NotTranchedModel() external givenNotNull {
        lockupModel = Lockup.Model.LOCKUP_LINEAR;
        uint256 streamId = createDefaultStream();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupState_NotExpectedModel.selector,
                Lockup.Model.LOCKUP_LINEAR,
                Lockup.Model.LOCKUP_TRANCHED
            )
        );
        lockup.getTranches(streamId);
    }

    function test_GivenTranchedModel() external givenNotNull {
        LockupTranched.Tranche[] memory actualTranches = lockup.getTranches(ids.defaultStream);
        LockupTranched.Tranche[] memory expectedTranches = defaults.tranches();
        assertEq(actualTranches, expectedTranches);
    }
}
