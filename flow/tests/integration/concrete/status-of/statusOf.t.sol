// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Flow } from "src/types/DataTypes.sol";

import { Shared_Integration_Concrete_Test } from "../Concrete.t.sol";

contract StatusOf_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function setUp() public override {
        Shared_Integration_Concrete_Test.setUp();

        depositToDefaultStream();
    }

    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.statusOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GivenNotStarted() external givenNotNull {
        uint256 streamId = flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            startTime: getBlockTimestamp() + 1 days,
            token: dai,
            transferable: TRANSFERABLE
        });

        // it should return PENDING
        uint8 actualStatus = uint8(flow.statusOf(streamId));
        uint8 expectedStatus = uint8(Flow.Status.PENDING);
        assertEq(actualStatus, expectedStatus);
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
