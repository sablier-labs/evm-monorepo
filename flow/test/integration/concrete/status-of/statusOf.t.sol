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

    function test_GivenVoided() external givenNotNull {
        // Simulate the passage of time to accumulate uncovered debt for one month.
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD + ONE_MONTH });
        flow.void(defaultStreamId);

        // it should return VOIDED
        uint8 actualStatus = uint8(flow.statusOf(defaultStreamId));
        uint8 expectedStatus = uint8(Flow.Status.VOIDED);
        assertEq(actualStatus, expectedStatus);
    }

    function test_GivenPausedAndNoUncoveredDebt() external givenNotNull {
        flow.pause(defaultStreamId);

        // it should return PAUSED_SOLVENT
        uint8 actualStatus = uint8(flow.statusOf(defaultStreamId));
        uint8 expectedStatus = uint8(Flow.Status.PAUSED_SOLVENT);
        assertEq(actualStatus, expectedStatus);
    }

    function test_GivenPausedAndUncoveredDebt() external givenNotNull {
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD + 1 });
        flow.pause(defaultStreamId);

        // it should return PAUSED_INSOLVENT
        uint8 actualStatus = uint8(flow.statusOf(defaultStreamId));
        uint8 expectedStatus = uint8(Flow.Status.PAUSED_INSOLVENT);
        assertEq(actualStatus, expectedStatus);
    }

    function test_GivenStreamingAndNoUncoveredDebt() external view givenNotNull {
        // it should return STREAMING_SOLVENT
        uint8 actualStatus = uint8(flow.statusOf(defaultStreamId));
        uint8 expectedStatus = uint8(Flow.Status.STREAMING_SOLVENT);
        assertEq(actualStatus, expectedStatus);
    }

    function test_GivenStreamingAndUncoveredDebt() external givenNotNull {
        // it should return STREAMING_INSOLVENT
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD + 1 });

        // it should return STREAMING_INSOLVENT
        uint8 actualStatus = uint8(flow.statusOf(defaultStreamId));
        uint8 expectedStatus = uint8(Flow.Status.STREAMING_INSOLVENT);
        assertEq(actualStatus, expectedStatus);
    }
}
