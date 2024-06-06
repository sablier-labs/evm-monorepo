// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract RestartAndDeposit_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Pause the stream for this test.
        flow.pause({ streamId: defaultStreamId });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(flow.restartAndDeposit, (defaultStreamId, RATE_PER_SECOND, TRANSFER_AMOUNT));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.restartAndDeposit, (nullStreamId, RATE_PER_SECOND, TRANSFER_AMOUNT));
        expectRevert_Null(callData);
    }

    function test_RevertWhen_CallerRecipient() external whenNoDelegateCall givenNotNull whenCallerNotSender {
        bytes memory callData =
            abi.encodeCall(flow.restartAndDeposit, (defaultStreamId, RATE_PER_SECOND, TRANSFER_AMOUNT));
        expectRevert_CallerRecipient(callData);
    }

    function test_RevertWhen_CallerMaliciousThirdParty() external whenNoDelegateCall givenNotNull whenCallerNotSender {
        bytes memory callData =
            abi.encodeCall(flow.restartAndDeposit, (defaultStreamId, RATE_PER_SECOND, TRANSFER_AMOUNT));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_WhenCallerSender() external whenNoDelegateCall givenNotNull {
        // It should perfor the ERC20 transfer.
        // It should emit 1 {RestartFlowStream}, 1 {Transfer}, 1 {DepositFlowStream} and 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit RestartFlowStream({
            streamId: defaultStreamId,
            sender: users.sender,
            asset: dai,
            ratePerSecond: RATE_PER_SECOND
        });

        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: users.sender, to: address(flow), value: TRANSFER_AMOUNT });

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({
            streamId: defaultStreamId,
            funder: users.sender,
            asset: dai,
            depositAmount: DEPOSIT_AMOUNT
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        // It should perform the ERC20 transfer.
        expectCallToTransferFrom({ asset: dai, from: users.sender, to: address(flow), amount: TRANSFER_AMOUNT });

        flow.restartAndDeposit({
            streamId: defaultStreamId,
            ratePerSecond: RATE_PER_SECOND,
            transferAmount: TRANSFER_AMOUNT
        });

        // It should restart the stream.
        bool isPaused = flow.isPaused(defaultStreamId);
        assertFalse(isPaused);

        // It should update the rate per second.
        uint128 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, RATE_PER_SECOND, "ratePerSecond");

        // It should update lastTimeUpdate.
        uint40 actualLastTimeUpdate = flow.getLastTimeUpdate(defaultStreamId);
        assertEq(actualLastTimeUpdate, getBlockTimestamp(), "lastTimeUpdate");

        // It should update the stream balance.
        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
