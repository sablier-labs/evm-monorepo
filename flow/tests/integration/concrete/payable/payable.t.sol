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

    function test_AdjustRatePerSecond_WhenETHValueNotZero() external {
        flow.adjustRatePerSecond{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, ud21x18(RATE_PER_SECOND_U128 + 1));
    }

    function test_Batch_WhenETHValueNotZero() external {
        bytes[] memory calls = new bytes[](0);
        flow.batch{ value: FLOW_MIN_FEE_WEI }(calls);
    }

    function test_Create_WhenETHValueNotZero() external {
        flow.create{ value: FLOW_MIN_FEE_WEI }(users.sender, users.recipient, RATE_PER_SECOND, ZERO, usdc, TRANSFERABLE);
    }

    function test_CreateAndDeposit_WhenETHValueNotZero() external {
        flow.createAndDeposit{ value: FLOW_MIN_FEE_WEI }(
            users.sender, users.recipient, RATE_PER_SECOND, ZERO, usdc, TRANSFERABLE, DEPOSIT_AMOUNT_6D
        );
    }

    function test_Deposit_WhenETHValueNotZero() external {
        flow.deposit{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, DEPOSIT_AMOUNT_6D, users.sender, users.recipient);
    }

    function test_DepositAndPause_WhenETHValueNotZero() external {
        flow.depositAndPause{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, DEPOSIT_AMOUNT_6D);
    }

    function test_Pause_WhenETHValueNotZero() external {
        flow.pause{ value: FLOW_MIN_FEE_WEI }(defaultStreamId);
    }

    function test_Refund_WhenETHValueNotZero() external {
        flow.refund{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, REFUND_AMOUNT_6D);
    }

    function test_RefundAndPause_WhenETHValueNotZero() external {
        flow.refundAndPause{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, REFUND_AMOUNT_6D);
    }

    function test_RefundMax_WhenETHValueNotZero() external {
        flow.refundMax{ value: FLOW_MIN_FEE_WEI }(defaultStreamId);
    }

    function test_Restart_WhenETHValueNotZero() external {
        flow.pause(defaultStreamId);
        flow.restart{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, RATE_PER_SECOND);
    }

    function test_RestartAndDeposit_WhenETHValueNotZero() external {
        flow.pause(defaultStreamId);
        flow.restartAndDeposit{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, RATE_PER_SECOND, DEPOSIT_AMOUNT_6D);
    }

    function test_Void_WhenETHValueNotZero() external {
        flow.void{ value: FLOW_MIN_FEE_WEI }(defaultStreamId);
    }

    function test_Withdraw_WhenETHValueNotZero() external {
        flow.withdraw{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, users.recipient, WITHDRAW_AMOUNT_6D);
    }

    function test_WithdrawMax_WhenETHValueNotZero() external {
        flow.withdrawMax{ value: FLOW_MIN_FEE_WEI }(defaultStreamId, users.recipient);
    }
}
