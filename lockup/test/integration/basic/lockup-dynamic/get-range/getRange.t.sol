// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Integration_Basic_Test } from "../Dynamic.t.sol";

contract GetRange_Dynamic_Integration_Basic_Test is Dynamic_Integration_Basic_Test {
    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        dynamic.getRange(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    function test_GetRange() external whenNotNull {
        uint256 streamId = createDefaultStream();
        LockupDynamic.Range memory actualRange = dynamic.getRange(streamId);
        LockupDynamic.Range memory expectedRange = defaults.dynamicRange();
        assertEq(actualRange, expectedRange);
    }
}
