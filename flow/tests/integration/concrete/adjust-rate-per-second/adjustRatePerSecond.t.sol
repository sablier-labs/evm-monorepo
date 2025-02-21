// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Flow } from "src/types/DataTypes.sol";

import { Shared_Integration_Concrete_Test } from "./../Concrete.t.sol";

contract AdjustRatePerSecond_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.adjustRatePerSecond, (defaultStreamId, RATE_PER_SECOND));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.adjustRatePerSecond, (nullStreamId, RATE_PER_SECOND));
        expectRevert_Null(callData);
    }

    function test_RevertGiven_Paused() external whenNoDelegateCall givenNotNull {
        bytes memory callData = abi.encodeCall(flow.adjustRatePerSecond, (defaultStreamId, RATE_PER_SECOND));
        expectRevert_Paused(callData);
    }

    function test_GivenPending() external whenNoDelegateCall givenNotNull givenNotPaused {
        vm.warp(flow.getSnapshotTime(defaultStreamId) - 1);
        assertEq(uint256(flow.statusOf(defaultStreamId)), uint256(Flow.Status.PENDING), "status not pending");

        uint128 newRatePerSecond = RATE_PER_SECOND_U128 + 1;

        uint40 previousSnapshotTime = flow.getSnapshotTime(defaultStreamId);
        uint256 previousSnapshotDebtScaled = flow.getSnapshotDebtScaled(defaultStreamId);

        flow.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: ud21x18(newRatePerSecond) });

        assertEq(previousSnapshotTime, flow.getSnapshotTime(defaultStreamId), "snapshot time");
        assertEq(previousSnapshotDebtScaled, flow.getSnapshotDebtScaled(defaultStreamId), "snapshot debt");
        assertEq(newRatePerSecond, flow.getRatePerSecond(defaultStreamId).unwrap(), "rate per second");
    }

    function test_RevertWhen_CallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        givenNotPending
        whenCallerNotSender
    {
        bytes memory callData = abi.encodeCall(flow.adjustRatePerSecond, (defaultStreamId, RATE_PER_SECOND));
        expectRevert_CallerRecipient(callData);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        givenNotPending
        whenCallerNotSender
    {
        bytes memory callData = abi.encodeCall(flow.adjustRatePerSecond, (defaultStreamId, RATE_PER_SECOND));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_RevertWhen_RatePerSecondZero()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        whenCallerSender
        givenNotPending
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_NewRatePerSecondZero.selector, defaultStreamId));
        flow.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: ud21x18(0) });
    }

    function test_RevertWhen_NewRatePerSecondEqualsCurrentRatePerSecond()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        whenCallerSender
        givenNotPending
        whenRatePerSecondNotZero
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_RatePerSecondNotDifferent.selector, defaultStreamId, RATE_PER_SECOND
            )
        );
        flow.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: RATE_PER_SECOND });
    }

    function test_WhenNewRatePerSecondNotEqualsCurrentRatePerSecond()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        whenCallerSender
        givenNotPending
        whenRatePerSecondNotZero
    {
        depositDefaultAmount(defaultStreamId);

        UD21x18 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        UD21x18 expectedRatePerSecond = RATE_PER_SECOND;
        assertEq(actualRatePerSecond, expectedRatePerSecond, "rate per second");

        uint40 actualSnapshotTime = flow.getSnapshotTime(defaultStreamId);
        uint40 expectedSnapshotTime = getBlockTimestamp() - ONE_MONTH;
        assertEq(actualSnapshotTime, expectedSnapshotTime, "snapshot time");

        uint256 actualSnapshotDebtScaled = flow.getSnapshotDebtScaled(defaultStreamId);
        uint128 expectedSnapshotDebtScaled = 0;
        assertEq(actualSnapshotDebtScaled, expectedSnapshotDebtScaled, "snapshot debt");

        UD21x18 newRatePerSecond = ud21x18(RATE_PER_SECOND.unwrap() / 2);

        // It should emit 1 {AdjustFlowStream}, 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.AdjustFlowStream({
            streamId: defaultStreamId,
            totalDebt: ONE_MONTH_DEBT_6D,
            oldRatePerSecond: RATE_PER_SECOND,
            newRatePerSecond: newRatePerSecond
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamId });

        flow.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: newRatePerSecond });

        assertEq(uint8(flow.statusOf(defaultStreamId)), uint8(Flow.Status.STREAMING_SOLVENT), "status not streaming");

        // It should update snapshot debt.
        actualSnapshotDebtScaled = flow.getSnapshotDebtScaled(defaultStreamId);
        expectedSnapshotDebtScaled = ONE_MONTH_DEBT_18D;
        assertEq(actualSnapshotDebtScaled, expectedSnapshotDebtScaled, "snapshot debt");

        // It should set the new rate per second
        actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        expectedRatePerSecond = newRatePerSecond;
        assertEq(actualRatePerSecond, expectedRatePerSecond, "rate per second");

        // It should update snapshot time
        actualSnapshotTime = flow.getSnapshotTime(defaultStreamId);
        expectedSnapshotTime = getBlockTimestamp();
        assertEq(actualSnapshotTime, expectedSnapshotTime, "snapshot time");
    }
}
