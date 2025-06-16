// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud21x18 } from "@prb/math/src/UD21x18.sol";

import { Shared_Integration_Concrete_Test } from "../Concrete.t.sol";

contract Payable_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function setUp() public override {
        Shared_Integration_Concrete_Test.setUp();
        depositToDefaultStream();

        vm.warp({ newTimestamp: ONE_MONTH_SINCE_CREATE });

        // Make the sender the caller.
        setMsgSender(users.sender);
    }

    function test_AdjustRatePerSecondWhenETHValueNotZero() external {
        flow.adjustRatePerSecond{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, ud21x18(RATE_PER_SECOND_U128 + 1));
    }

    function test_BatchWhenETHValueNotZero() external {
        bytes[] memory calls = new bytes[](0);
        flow.batch{ value: FLOW_MIN_FEE_WEI }(calls);
    }

    function test_CreateWhenETHValueNotZero() external {
        flow.create{ value: FLOW_MIN_FEE_WEI }(users.sender, users.recipient, RATE_PER_SECOND, ZERO, usdc, TRANSFERABLE);
    }

    function test_CreateAndDepositWhenETHValueNotZero() external {
        flow.createAndDeposit{ value: FLOW_MIN_FEE_WEI }(
            users.sender, users.recipient, RATE_PER_SECOND, ZERO, usdc, TRANSFERABLE, DEPOSIT_AMOUNT_6D
        );
    }

    function test_DepositWhenETHValueNotZero() external {
        flow.deposit{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, DEPOSIT_AMOUNT_6D, users.sender, users.recipient);
    }

    function test_DepositAndPauseWhenETHValueNotZero() external {
        flow.depositAndPause{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, DEPOSIT_AMOUNT_6D);
    }

    function test_PauseWhenETHValueNotZero() external {
        flow.pause{ value: FLOW_MIN_FEE_WEI }(defaultStreamId);
    }

    function test_RefundWhenETHValueNotZero() external {
        flow.refund{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, REFUND_AMOUNT_6D);
    }

    function test_RefundAndPauseWhenETHValueNotZero() external {
        flow.refundAndPause{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, REFUND_AMOUNT_6D);
    }

    function test_RefundMaxWhenETHValueNotZero() external {
        flow.refundMax{ value: FLOW_MIN_FEE_WEI }(defaultStreamId);
    }

    function test_RestartWhenETHValueNotZero() external {
        flow.pause(defaultStreamId);
        flow.restart{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, RATE_PER_SECOND);
    }

    function test_RestartAndDepositWhenETHValueNotZero() external {
        flow.pause(defaultStreamId);
        flow.restartAndDeposit{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, RATE_PER_SECOND, DEPOSIT_AMOUNT_6D);
    }

    function test_VoidWhenETHValueNotZero() external {
        flow.void{ value: FLOW_MIN_FEE_WEI }(defaultStreamId);
    }

    function test_WithdrawWhenETHValueNotZero() external {
        flow.withdraw{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, users.recipient, WITHDRAW_AMOUNT_6D);
    }

    function test_WithdrawMaxWhenETHValueNotZero() external {
        flow.withdrawMax{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, users.recipient);
    }
}
