// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract RefundAndPause_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        depositToDefaultStream();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.refundAndPause, (defaultStreamId, REFUND_AMOUNT));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.refundAndPause, (nullStreamId, REFUND_AMOUNT));
        expectRevert_Null(callData);
    }

    function test_RevertGiven_Paused() external whenNoDelegateCall givenNotNull {
        bytes memory callData = abi.encodeCall(flow.refundAndPause, (defaultStreamId, REFUND_AMOUNT));
        expectRevert_Paused(callData);
    }

    function test_RevertWhen_CallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        whenCallerNotSender
    {
        bytes memory callData = abi.encodeCall(flow.refundAndPause, (defaultStreamId, REFUND_AMOUNT));
        expectRevert_CallerRecipient(callData);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        whenCallerNotSender
    {
        bytes memory callData = abi.encodeCall(flow.refundAndPause, (defaultStreamId, REFUND_AMOUNT));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_WhenCallerSender() external whenNoDelegateCall givenNotNull givenNotPaused {
        uint128 previousAmountOwed = flow.amountOwedOf(defaultStreamId);

        // It should emit 1 {Transfer}, 1 {RefundFromFlowStream}, 1 {PauseFlowStream}, 1 {MetadataUpdate} events
        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: address(flow), to: users.sender, value: REFUND_AMOUNT });

        vm.expectEmit({ emitter: address(flow) });
        emit RefundFromFlowStream({ streamId: defaultStreamId, sender: users.sender, refundAmount: REFUND_AMOUNT });

        vm.expectEmit({ emitter: address(flow) });
        emit PauseFlowStream({
            streamId: defaultStreamId,
            recipient: users.recipient,
            sender: users.sender,
            amountOwed: previousAmountOwed
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        // It should perform the ERC20 transfer
        expectCallToTransfer({ asset: dai, to: users.sender, amount: REFUND_AMOUNT });

        flow.refundAndPause(defaultStreamId, REFUND_AMOUNT);

        // It should update the stream balance
        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - REFUND_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // It should pause the stream
        assertTrue(flow.isPaused(defaultStreamId), "is paused");

        // It should set rate per second to 0
        uint256 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        // It should update the remaining amount
        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        assertEq(actualRemainingAmount, previousAmountOwed, "remaining amount");
    }
}
