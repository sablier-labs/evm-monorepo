// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../../Integration.t.sol";

contract Pause_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.pause, (defaultStreamId));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.pause, (nullStreamId));
        expectRevert_Null(callData);
    }

    function test_RevertGiven_Paused() external whenNoDelegateCall givenNotNull {
        bytes memory callData = abi.encodeCall(flow.pause, (defaultStreamId));
        expectRevert_Paused(callData);
    }

    function test_RevertWhen_CallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        whenCallerNotSender
    {
        bytes memory callData = abi.encodeCall(flow.pause, (defaultStreamId));
        expectRevert_CallerRecipient(callData);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        whenCallerNotSender
    {
        bytes memory callData = abi.encodeCall(flow.pause, (defaultStreamId));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_GivenStreamHasDebt() external whenNoDelegateCall givenNotNull givenNotPaused whenCallerSender {
        // Simulate the passage of time to create debt.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // Check that debt is positive.
        assertGt(flow.streamDebtOf(defaultStreamId), 0, "stream debt");

        // It should pause the stream.
        test_Pause();
    }

    function test_GivenStreamHasNoDebt() external whenNoDelegateCall givenNotNull givenNotPaused whenCallerSender {
        // Simulate the passage of time to create debt.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // Make deposit to clear debt.
        depositDefaultAmountToDefaultStream();

        // Check that debt is zero.
        assertEq(flow.streamDebtOf(defaultStreamId), 0, "stream debt");

        // It should pause the stream.
        test_Pause();
    }

    function test_Pause() internal {
        uint128 previousAmountOwed = flow.amountOwedOf(defaultStreamId);

        // It should emit 1 {PauseFlowStream}, 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit PauseFlowStream({
            streamId: defaultStreamId,
            recipient: users.recipient,
            sender: users.sender,
            amountOwed: previousAmountOwed
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        flow.pause(defaultStreamId);

        // It should pause the stream.
        assertTrue(flow.isPaused(defaultStreamId), "is paused");

        // It should set the rate per second to zero.
        uint256 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        // It should update the remaining amount.
        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        assertEq(actualRemainingAmount, previousAmountOwed, "remaining amount");
    }
}
