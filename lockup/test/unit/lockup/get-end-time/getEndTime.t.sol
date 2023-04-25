// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract GetEndTime_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) { }

    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.getEndTime(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    function test_GetEndTime() external whenNotNull {
        uint256 streamId = createDefaultStream();
        uint40 actualEndTime = lockup.getEndTime(streamId);
        uint40 expectedEndTime = DEFAULT_END_TIME;
        assertEq(actualEndTime, expectedEndTime, "endTime");
    }
}
