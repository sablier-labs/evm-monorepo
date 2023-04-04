// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract GetCliffTime_Linear_Unit_Test is Linear_Unit_Test {
    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        linear.getCliffTime(nullStreamId);
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return the correct cliff time.
    function test_GetCliffTime() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        uint40 actualCliffTime = linear.getCliffTime(streamId);
        uint40 expectedCliffTime = DEFAULT_CLIFF_TIME;
        assertEq(actualCliffTime, expectedCliffTime, "cliffTime");
    }
}
