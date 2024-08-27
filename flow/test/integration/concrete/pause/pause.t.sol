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

    function test_GivenUncoveredDebt() external whenNoDelegateCall givenNotNull givenNotPaused whenCallerSender {
        // Check that uncovered debt is greater than zero.
        assertGt(flow.uncoveredDebtOf(defaultStreamId), 0, "uncovered debt");

        // It should pause the stream.
        test_Pause();
    }

    function test_GivenNoUncoveredDebt() external whenNoDelegateCall givenNotNull givenNotPaused whenCallerSender {
        // Make deposit to repay uncovered debt.
        depositToDefaultStream();

        // Check that uncovered debt is zero.
        assertEq(flow.uncoveredDebtOf(defaultStreamId), 0, "uncovered debt");

        // It should pause the stream.
        test_Pause();
    }

    function test_Pause() internal {
        uint128 initialTotalDebt = flow.totalDebtOf(defaultStreamId);

        // It should emit 1 {PauseFlowStream}, 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit PauseFlowStream({
            streamId: defaultStreamId,
            sender: users.sender,
            recipient: users.recipient,
            totalDebt: initialTotalDebt
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        flow.pause(defaultStreamId);

        // It should pause the stream.
        assertTrue(flow.isPaused(defaultStreamId), "is paused");

        // It should set the rate per second to zero.
        uint256 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        // It should update the snapshot debt.
        uint128 actualSnapshotDebt = flow.getSnapshotDebt(defaultStreamId);
        assertEq(actualSnapshotDebt, initialTotalDebt, "snapshot debt");
    }
}
