// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LockupDynamic } from "src/types/DataTypes.sol";

import { LockupDynamic_Integration_Concrete_Test } from "../LockupDynamic.t.sol";

contract GetRange_LockupDynamic_Integration_Concrete_Test is LockupDynamic_Integration_Concrete_Test {
    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockupDynamic.getRange(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    function test_GetRange() external whenNotNull {
        uint256 streamId = createDefaultStream();
        LockupDynamic.Range memory actualRange = lockupDynamic.getRange(streamId);
        LockupDynamic.Range memory expectedRange = defaults.lockupDynamicRange();
        assertEq(actualRange, expectedRange);
    }
}
