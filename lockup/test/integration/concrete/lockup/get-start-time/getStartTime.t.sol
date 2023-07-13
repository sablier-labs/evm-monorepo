// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract GetStartTime_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) { }

    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.getStartTime(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    function test_GetStartTime() external whenNotNull {
        uint256 streamId = createDefaultStream();
        uint40 actualStartTime = lockup.getStartTime(streamId);
        uint40 expectedStartTime = defaults.START_TIME();
        assertEq(actualStartTime, expectedStartTime, "startTime");
    }
}
