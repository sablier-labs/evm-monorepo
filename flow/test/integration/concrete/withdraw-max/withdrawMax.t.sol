// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract WithdrawMax_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        depositToDefaultStream();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.withdrawMax, (defaultStreamId, users.recipient));
        expectRevert_DelegateCall(callData);
    }

    function test_WithdrawMax_Paused() external {
        flow.pause(defaultStreamId);

        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: address(flow), to: users.recipient, value: ONE_MONTH_STREAMED_AMOUNT });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: defaultStreamId,
            to: users.recipient,
            asset: dai,
            withdrawnAmount: ONE_MONTH_STREAMED_AMOUNT
        });

        flow.withdrawMax(defaultStreamId, users.recipient);

        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        assertEq(actualRemainingAmount, 0, "remaining amount");
        assertEq(flow.getLastTimeUpdate(defaultStreamId), WARP_ONE_MONTH, "last time update not updated");
    }

    function test_WithdrawMax() external givenNotPaused {
        uint128 beforeStreamBalance = flow.getBalance(defaultStreamId);
        uint128 beforeRemainingAmount = flow.getRemainingAmount(defaultStreamId);

        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({
            from: address(flow),
            to: users.recipient,
            value: normalizeAmountWithStreamId(defaultStreamId, ONE_MONTH_STREAMED_AMOUNT)
        });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: defaultStreamId,
            to: users.recipient,
            asset: dai,
            withdrawnAmount: beforeRemainingAmount + ONE_MONTH_STREAMED_AMOUNT
        });

        flow.withdrawMax(defaultStreamId, users.recipient);

        uint128 afterStreamBalance = flow.getBalance(defaultStreamId);
        uint128 afterRemainingAmount = flow.getRemainingAmount(defaultStreamId);

        assertEq(
            beforeStreamBalance - ONE_MONTH_STREAMED_AMOUNT, afterStreamBalance, "stream balance not updated correctly"
        );
        assertEq(afterRemainingAmount, 0, "remaining amount should be 0");
        assertEq(flow.getLastTimeUpdate(defaultStreamId), WARP_ONE_MONTH, "last time update not updated");
    }
}
