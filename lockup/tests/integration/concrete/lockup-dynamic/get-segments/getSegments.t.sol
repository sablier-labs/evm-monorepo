// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupDynamic } from "src/types/LockupDynamic.sol";

import { Lockup_Dynamic_Integration_Concrete_Test } from "../LockupDynamic.t.sol";

contract GetSegments_Integration_Concrete_Test is Lockup_Dynamic_Integration_Concrete_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null({ callData: abi.encodeCall(lockup.getSegments, ids.nullStream) });
    }

    function test_RevertGiven_NotDynamicModel() external givenNotNull {
        lockupModel = Lockup.Model.LOCKUP_LINEAR;
        uint256 streamId = createDefaultStream();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupState_NotExpectedModel.selector,
                Lockup.Model.LOCKUP_LINEAR,
                Lockup.Model.LOCKUP_DYNAMIC
            )
        );
        lockup.getSegments(streamId);
    }

    function test_GivenDynamicModel() external givenNotNull {
        LockupDynamic.Segment[] memory actualSegments = lockup.getSegments(ids.defaultStream);
        LockupDynamic.Segment[] memory expectedSegments = defaults.segments();
        assertEq(actualSegments, expectedSegments);
    }
}
