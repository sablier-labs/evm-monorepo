// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LockupLinear } from "src/types/DataTypes.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract GetRange_Linear_Unit_Test is Linear_Unit_Test {
    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        linear.getRange(nullStreamId);
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return the correct range.
    function test_GetRange() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        LockupLinear.Range memory actualRange = linear.getRange(streamId);
        LockupLinear.Range memory expectedRange = DEFAULT_LINEAR_RANGE;
        assertEq(actualRange, expectedRange);
    }
}
