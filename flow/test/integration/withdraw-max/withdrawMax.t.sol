// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Integration_Test } from "../Integration.t.sol";

contract WithdrawMax_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        defaultDeposit();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_WithdrawMax_Canceled() external {
        openEnded.cancel(defaultStreamId);

        uint128 beforeStreamBalance = openEnded.getBalance(defaultStreamId);
        uint128 beforeRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);

        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({
            from: address(openEnded),
            to: users.recipient,
            value: normalizeTransferAmount(defaultStreamId, beforeRemainingAmount)
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit WithdrawFromOpenEndedStream({
            streamId: defaultStreamId,
            to: users.recipient,
            asset: dai,
            withdrawnAmount: beforeRemainingAmount
        });

        openEnded.withdrawMax(defaultStreamId, users.recipient);

        uint128 afterStreamBalance = openEnded.getBalance(defaultStreamId);
        uint128 afterRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);

        assertEq(beforeStreamBalance, afterStreamBalance, "stream balance should not change");
        assertEq(afterRemainingAmount, 0, "remaining amount should be 0");
        assertEq(openEnded.getLastTimeUpdate(defaultStreamId), WARP_ONE_MONTH, "last time update not updated");
    }

    function test_WithdrawMax() external givenNotCanceled {
        uint128 beforeStreamBalance = openEnded.getBalance(defaultStreamId);
        uint128 beforeRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);

        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({
            from: address(openEnded),
            to: users.recipient,
            value: normalizeTransferAmount(defaultStreamId, ONE_MONTH_STREAMED_AMOUNT)
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit WithdrawFromOpenEndedStream({
            streamId: defaultStreamId,
            to: users.recipient,
            asset: dai,
            withdrawnAmount: beforeRemainingAmount + ONE_MONTH_STREAMED_AMOUNT
        });

        openEnded.withdrawMax(defaultStreamId, users.recipient);

        uint128 afterStreamBalance = openEnded.getBalance(defaultStreamId);
        uint128 afterRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);

        assertEq(
            beforeStreamBalance - ONE_MONTH_STREAMED_AMOUNT, afterStreamBalance, "stream balance not updated correctly"
        );
        assertEq(afterRemainingAmount, 0, "remaining amount should be 0");
        assertEq(openEnded.getLastTimeUpdate(defaultStreamId), WARP_ONE_MONTH, "last time update not updated");
    }
}
