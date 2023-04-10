// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract GetRange_Dynamic_Unit_Test is Dynamic_Unit_Test {
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        dynamic.getRange(nullStreamId);
    }

    modifier whenStreamNonNull() {
        _;
    }

    function test_GetRange() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        LockupDynamic.Range memory actualRange = dynamic.getRange(streamId);
        LockupDynamic.Range memory expectedRange = DEFAULT_DYNAMIC_RANGE;
        assertEq(actualRange, expectedRange);
    }
}
