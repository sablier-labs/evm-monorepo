// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract GetStream_Dynamic_Unit_Test is Dynamic_Unit_Test {
    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        dynamic.getStream(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    function test_GetStream() external whenNotNull {
        uint256 streamId = createDefaultStream();
        LockupDynamic.Stream memory actualStream = dynamic.getStream(streamId);
        LockupDynamic.Stream memory expectedStream = defaultStream;
        assertEq(actualStream, expectedStream);
    }
}
