// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Flow } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract StatusOf_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        depositToDefaultStream();
    }

    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.statusOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GivenPausedAndNoDebt() external givenNotNull {
        flow.pause(defaultStreamId);

        // it should return PAUSED_SOLVENT
        uint8 actualStatus = uint8(flow.statusOf(defaultStreamId));
        uint8 expectedStatus = uint8(Flow.Status.PAUSED_SOLVENT);
        assertEq(actualStatus, expectedStatus);
    }

    function test_GivenPausedAndDebt() external givenNotNull {
        // it should return PAUSED_INSOLVENT
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD + 1 });
        flow.pause(defaultStreamId);

        // it should return PAUSED_INSOLVENT
        uint8 actualStatus = uint8(flow.statusOf(defaultStreamId));
        uint8 expectedStatus = uint8(Flow.Status.PAUSED_INSOLVENT);
        assertEq(actualStatus, expectedStatus);
    }

    function test_GivenStreamingAndNoDebt() external view givenNotNull {
        // it should return STREAMING_SOLVENT
        uint8 actualStatus = uint8(flow.statusOf(defaultStreamId));
        uint8 expectedStatus = uint8(Flow.Status.STREAMING_SOLVENT);
        assertEq(actualStatus, expectedStatus);
    }

    function test_GivenStreamingAndDebt() external givenNotNull {
        // it should return STREAMING_INSOLVENT
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD + 1 });

        // it should return STREAMING_INSOLVENT
        uint8 actualStatus = uint8(flow.statusOf(defaultStreamId));
        uint8 expectedStatus = uint8(Flow.Status.STREAMING_INSOLVENT);
        assertEq(actualStatus, expectedStatus);
    }
}
