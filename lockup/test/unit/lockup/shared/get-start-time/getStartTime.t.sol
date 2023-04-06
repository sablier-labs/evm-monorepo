// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetStartTime_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) { }

    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        lockup.getStartTime(nullStreamId);
    }

    modifier whenStreamNonNull() {
        _;
    }

    function test_GetStartTime() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        uint40 actualStartTime = lockup.getStartTime(streamId);
        uint40 expectedStartTime = DEFAULT_START_TIME;
        assertEq(actualStartTime, expectedStartTime, "startTime");
    }
}
