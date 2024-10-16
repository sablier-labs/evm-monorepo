// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract DepositAndPause_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Advance the time past the solvency period so that there is uncovered debt.
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD + 1 days });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.depositAndPause, (defaultStreamId, DEPOSIT_AMOUNT_6D));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.depositAndPause, (nullStreamId, DEPOSIT_AMOUNT_6D));
        expectRevert_Null(callData);
    }

    function test_RevertGiven_Paused() external whenNoDelegateCall givenNotNull {
        bytes memory callData = abi.encodeCall(flow.depositAndPause, (defaultStreamId, DEPOSIT_AMOUNT_6D));
        expectRevert_Paused(callData);
    }

    function test_RevertWhen_CallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        whenCallerNotSender
    {
        bytes memory callData = abi.encodeCall(flow.depositAndPause, (defaultStreamId, DEPOSIT_AMOUNT_6D));
        expectRevert_CallerRecipient(callData);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        whenCallerNotSender
    {
        bytes memory callData = abi.encodeCall(flow.depositAndPause, (defaultStreamId, DEPOSIT_AMOUNT_6D));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_WhenCallerSender() external whenNoDelegateCall givenNotNull givenNotPaused {
        uint128 previousStreamBalance = flow.getBalance(defaultStreamId);
        uint256 expectedSnapshotDebtScaled =
            flow.getSnapshotDebtScaled(defaultStreamId) + flow.ongoingDebtScaledOf(defaultStreamId);

        // It should emit 1 {Transfer}, 1 {DepositFlowStream}, 1 {PauseFlowStream}, 1 {MetadataUpdate} events
        vm.expectEmit({ emitter: address(usdc) });
        emit IERC20.Transfer({ from: users.sender, to: address(flow), value: DEPOSIT_AMOUNT_6D });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.DepositFlowStream({
            streamId: defaultStreamId,
            funder: users.sender,
            amount: DEPOSIT_AMOUNT_6D
        });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.PauseFlowStream({
            streamId: defaultStreamId,
            sender: users.sender,
            recipient: users.recipient,
            totalDebt: flow.totalDebtOf(defaultStreamId)
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamId });

        // It should perform the ERC-20 transfer
        expectCallToTransferFrom({ token: usdc, from: users.sender, to: address(flow), amount: DEPOSIT_AMOUNT_6D });

        flow.depositAndPause(defaultStreamId, DEPOSIT_AMOUNT_6D);

        // It should update the stream balance
        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = previousStreamBalance + DEPOSIT_AMOUNT_6D;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // It should pause the stream
        assertTrue(flow.isPaused(defaultStreamId), "is paused");

        // It should set rate per second to 0
        UD21x18 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        // It should update the snapshot debt
        uint256 actualSnapshotDebtScaled = flow.getSnapshotDebtScaled(defaultStreamId);
        assertEq(actualSnapshotDebtScaled, expectedSnapshotDebtScaled, "snapshot debt");
    }
}
