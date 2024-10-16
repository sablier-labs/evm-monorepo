// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

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
        _test_Pause();
    }

    function test_GivenNoUncoveredDebt() external whenNoDelegateCall givenNotNull givenNotPaused whenCallerSender {
        // Make deposit to repay uncovered debt.
        depositToDefaultStream();

        // Check that uncovered debt is zero.
        assertEq(flow.uncoveredDebtOf(defaultStreamId), 0, "uncovered debt");

        // It should pause the stream.
        _test_Pause();
    }

    function _test_Pause() private {
        // It should emit 1 {PauseFlowStream}, 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.PauseFlowStream({
            streamId: defaultStreamId,
            sender: users.sender,
            recipient: users.recipient,
            totalDebt: flow.totalDebtOf(defaultStreamId)
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamId });

        flow.pause(defaultStreamId);

        // It should pause the stream.
        assertTrue(flow.isPaused(defaultStreamId), "is paused");

        // It should set the rate per second to zero.
        UD21x18 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        // It should update the snapshot debt.
        uint256 actualSnapshotDebtScaled = flow.getSnapshotDebtScaled(defaultStreamId);
        assertEq(actualSnapshotDebtScaled, ONE_MONTH_DEBT_18D, "snapshot debt");
    }
}
