// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LockupLinear } from "src/types/DataTypes.sol";

import { Linear_Integration_Basic_Test } from "../Linear.t.sol";

contract GetRange_Linear_Integration_Basic_Test is Linear_Integration_Basic_Test {
    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        linear.getRange(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    function test_GetRange() external whenNotNull {
        uint256 streamId = createDefaultStream();
        LockupLinear.Range memory actualRange = linear.getRange(streamId);
        LockupLinear.Range memory expectedRange = defaults.linearRange();
        assertEq(actualRange, expectedRange);
    }
}
