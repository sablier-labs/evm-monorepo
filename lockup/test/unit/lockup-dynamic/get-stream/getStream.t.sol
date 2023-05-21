// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract GetStream_Dynamic_Unit_Test is Dynamic_Unit_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        Dynamic_Unit_Test.setUp();
        defaultStreamId = createDefaultStream();
    }

    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        dynamic.getStream(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    function test_GetStream_StatusSettled() external whenNotNull {
        vm.warp({ timestamp: defaults.END_TIME() });
        LockupDynamic.Stream memory actualStream = dynamic.getStream(defaultStreamId);
        LockupDynamic.Stream memory expectedStream = defaults.dynamicStream();
        expectedStream.isCancelable = false;
        assertEq(actualStream, expectedStream);
    }

    modifier whenStatusNotSettled() {
        _;
    }

    function test_GetStream() external whenNotNull whenStatusNotSettled {
        uint256 streamId = createDefaultStream();
        LockupDynamic.Stream memory actualStream = dynamic.getStream(streamId);
        LockupDynamic.Stream memory expectedStream = defaults.dynamicStream();
        assertEq(actualStream, expectedStream);
    }
}
