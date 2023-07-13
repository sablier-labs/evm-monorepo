// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LockupLinear } from "src/types/DataTypes.sol";

import { LockupLinear_Integration_Concrete_Test } from "../LockupLinear.t.sol";

contract GetRange_LockupLinear_Integration_Concrete_Test is LockupLinear_Integration_Concrete_Test {
    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockupLinear.getRange(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    function test_GetRange() external whenNotNull {
        uint256 streamId = createDefaultStream();
        LockupLinear.Range memory actualRange = lockupLinear.getRange(streamId);
        LockupLinear.Range memory expectedRange = defaults.lockupLinearRange();
        assertEq(actualRange, expectedRange);
    }
}
