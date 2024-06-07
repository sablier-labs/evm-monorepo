// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract WithdrawMax_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Deposit to the default stream.
        depositDefaultAmountToDefaultStream();

        // Simulate one month of streaming.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.withdrawMax, (defaultStreamId, users.recipient));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.withdrawMax, (nullStreamId, users.recipient));
        expectRevert_Null(callData);
    }

    function test_GivenPaused() external whenNoDelegateCall givenNotNull {
        // Pause the stream.
        flow.pause(defaultStreamId);

        // Withdraw the maximum amount.
        _test_WithdrawMax();
    }

    function test_GivenNotPaused() external whenNoDelegateCall givenNotNull {
        // Withdraw the maximum amount.
        _test_WithdrawMax();
    }

    function _test_WithdrawMax() private {
        // It should emit 1 {Transfer}, 1 {WithdrawFromFlowStream} and 1 {MetadataUpdated} events.
        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: address(flow), to: users.recipient, value: ONE_MONTH_STREAMED_AMOUNT });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: defaultStreamId,
            to: users.recipient,
            asset: dai,
            withdrawnAmount: ONE_MONTH_STREAMED_AMOUNT
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        // It should perform the ERC20 transfer
        expectCallToTransfer({
            asset: dai,
            to: users.recipient,
            amount: getTransferAmount(ONE_MONTH_STREAMED_AMOUNT, 18)
        });

        flow.withdrawMax(defaultStreamId, users.recipient);

        // It should update the stream balance.
        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // It should set the remaining amount to zero.
        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        assertEq(actualRemainingAmount, 0, "remaining amount");

        // It should update lastTimeUpdate.
        uint128 actualLastTimeUpdate = flow.getLastTimeUpdate(defaultStreamId);
        assertEq(actualLastTimeUpdate, getBlockTimestamp(), "last time update");
    }
}
