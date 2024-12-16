// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud21x18 } from "@prb/math/src/UD21x18.sol";

import { Shared_Integration_Concrete_Test } from "../Concrete.t.sol";

contract Payable_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function setUp() public override {
        Shared_Integration_Concrete_Test.setUp();
        depositToDefaultStream();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // Make the sender the caller.
        resetPrank({ msgSender: users.sender });
    }

    function test_AdjustRatePerSecondWhenETHValueNotZero() external {
        flow.adjustRatePerSecond{ value: FEE }(defaultStreamId, ud21x18(RATE_PER_SECOND_U128 + 1));
    }

    function test_CreateWhenETHValueNotZero() external {
        flow.create{ value: FEE }(users.sender, users.recipient, RATE_PER_SECOND, usdc, TRANSFERABLE);
    }

    function test_CreateAndDepositWhenETHValueNotZero() external {
        flow.createAndDeposit{ value: FEE }(
            users.sender, users.recipient, RATE_PER_SECOND, usdc, TRANSFERABLE, DEPOSIT_AMOUNT_6D
        );
    }

    function test_DepositWhenETHValueNotZero() external {
        flow.deposit{ value: FEE }(defaultStreamId, DEPOSIT_AMOUNT_6D, users.sender, users.recipient);
    }

    function test_DepositAndPauseWhenETHValueNotZero() external {
        flow.depositAndPause{ value: FEE }(defaultStreamId, DEPOSIT_AMOUNT_6D);
    }

    function test_DepositViaBrokerWhenETHValueNotZero() external {
        flow.depositViaBroker{ value: FEE }(
            defaultStreamId, DEPOSIT_AMOUNT_6D, users.sender, users.recipient, defaultBroker
        );
    }

    function test_PauseWhenETHValueNotZero() external {
        flow.pause{ value: FEE }(defaultStreamId);
    }

    function test_RefundWhenETHValueNotZero() external {
        flow.refund{ value: FEE }(defaultStreamId, REFUND_AMOUNT_6D);
    }

    function test_RefundAndPauseWhenETHValueNotZero() external {
        flow.refundAndPause{ value: FEE }(defaultStreamId, REFUND_AMOUNT_6D);
    }

    function test_RefundMaxWhenETHValueNotZero() external {
        flow.refundMax{ value: FEE }(defaultStreamId);
    }

    function test_RestartWhenETHValueNotZero() external {
        flow.pause(defaultStreamId);
        flow.restart{ value: FEE }(defaultStreamId, RATE_PER_SECOND);
    }

    function test_RestartAndDepositWhenETHValueNotZero() external {
        flow.pause(defaultStreamId);
        flow.restartAndDeposit{ value: FEE }(defaultStreamId, RATE_PER_SECOND, DEPOSIT_AMOUNT_6D);
    }

    function test_VoidWhenETHValueNotZero() external {
        flow.void{ value: FEE }(defaultStreamId);
    }

    function test_WithdrawWhenETHValueNotZero() external {
        flow.withdraw{ value: FEE }(defaultStreamId, users.recipient, WITHDRAW_AMOUNT_6D);
    }

    function test_WithdrawMaxWhenETHValueNotZero() external {
        flow.withdrawMax{ value: FEE }(defaultStreamId, users.recipient);
    }
}
