// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";
import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Shared_Integration_Concrete_Test } from "./../Concrete.t.sol";

contract Batch_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    uint256[] internal defaultStreamIds;

    function setUp() public override {
        Shared_Integration_Concrete_Test.setUp();

        // The first stream is the default stream.
        defaultStreamIds.push(defaultStreamId);
        // Create a new stream as the second stream.
        defaultStreamIds.push(createDefaultStream());
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       REVERT
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The batch call pauses a null stream.
    function test_RevertWhen_FlowThrows() external {
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.pause, (defaultStreamId));
        calls[1] = abi.encodeCall(flow.pause, (nullStreamId));

        // It should revert on nullStreamId.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlowState_Null.selector, nullStreamId));
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               ADJUST-RATE-PER-SECOND
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_AdjustRatePerSecond() external {
        UD21x18 newRatePerSecond = ud21x18(RATE_PER_SECOND.unwrap() + 1);

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.adjustRatePerSecond, (defaultStreamIds[0], newRatePerSecond));
        calls[1] = abi.encodeCall(flow.adjustRatePerSecond, (defaultStreamIds[1], newRatePerSecond));

        // It should emit 2 {AdjustRatePerSecond} events.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.AdjustFlowStream({
            streamId: defaultStreamIds[0],
            totalDebt: ONE_MONTH_DEBT_6D,
            oldRatePerSecond: RATE_PER_SECOND,
            newRatePerSecond: newRatePerSecond
        });
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.AdjustFlowStream({
            streamId: defaultStreamIds[1],
            totalDebt: 0,
            oldRatePerSecond: RATE_PER_SECOND,
            newRatePerSecond: newRatePerSecond
        });

        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      CREATE
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_Create() external {
        uint256 expectedNextStreamId = flow.nextStreamId();

        bytes[] memory calls = new bytes[](2);
        calls[0] =
            abi.encodeCall(flow.create, (users.sender, users.recipient, RATE_PER_SECOND, ZERO, usdc, TRANSFERABLE));
        calls[1] =
            abi.encodeCall(flow.create, (users.sender, users.recipient, RATE_PER_SECOND, ZERO, usdc, TRANSFERABLE));

        // Call the batch function.
        bytes[] memory results = flow.batch(calls);
        assertEq(results.length, 2, "batch results length");
        assertEq(abi.decode(results[0], (uint256)), expectedNextStreamId, "batch results[0]");
        assertEq(abi.decode(results[1], (uint256)), expectedNextStreamId + 1, "batch results[1]");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      DEPOSIT
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_Deposit() external {
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.deposit, (defaultStreamIds[0], DEPOSIT_AMOUNT_6D, users.sender, users.recipient));
        calls[1] = abi.encodeCall(flow.deposit, (defaultStreamIds[1], DEPOSIT_AMOUNT_6D, users.sender, users.recipient));

        // It should emit 2 {DepositFlowStream} events.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.DepositFlowStream({
            streamId: defaultStreamIds[0],
            funder: users.sender,
            amount: DEPOSIT_AMOUNT_6D
        });
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.DepositFlowStream({
            streamId: defaultStreamIds[1],
            funder: users.sender,
            amount: DEPOSIT_AMOUNT_6D
        });

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({ token: usdc, from: users.sender, to: address(flow), value: DEPOSIT_AMOUNT_6D });
        expectCallToTransferFrom({ token: usdc, from: users.sender, to: address(flow), value: DEPOSIT_AMOUNT_6D });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       PAUSE
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_Pause() external {
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.pause, (defaultStreamIds[0]));
        calls[1] = abi.encodeCall(flow.pause, (defaultStreamIds[1]));

        // It should emit 2 {PauseFlowStream} events.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.PauseFlowStream({
            streamId: defaultStreamIds[0],
            recipient: users.recipient,
            sender: users.sender,
            totalDebt: ONE_MONTH_DEBT_6D
        });
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.PauseFlowStream({
            streamId: defaultStreamIds[1],
            sender: users.sender,
            recipient: users.recipient,
            totalDebt: 0
        });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       REFUND
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_Refund() external {
        depositDefaultAmount(defaultStreamIds[0]);
        depositDefaultAmount(defaultStreamIds[1]);

        // The calls declared as bytes.
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.refund, (defaultStreamIds[0], REFUND_AMOUNT_6D));
        calls[1] = abi.encodeCall(flow.refund, (defaultStreamIds[1], REFUND_AMOUNT_6D));

        // It should emit 2 {RefundFromFlowStream} events.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RefundFromFlowStream({
            streamId: defaultStreamIds[0],
            sender: users.sender,
            amount: REFUND_AMOUNT_6D
        });
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RefundFromFlowStream({
            streamId: defaultStreamIds[1],
            sender: users.sender,
            amount: REFUND_AMOUNT_6D
        });

        // It should perform the ERC-20 transfers.
        expectCallToTransfer({ token: usdc, to: users.sender, value: REFUND_AMOUNT_6D });
        expectCallToTransfer({ token: usdc, to: users.sender, value: REFUND_AMOUNT_6D });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      RESTART
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_Restart() external {
        flow.pause({ streamId: defaultStreamIds[0] });
        flow.pause({ streamId: defaultStreamIds[1] });

        // The calls declared as bytes.
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.restart, (defaultStreamIds[0], RATE_PER_SECOND));
        calls[1] = abi.encodeCall(flow.restart, (defaultStreamIds[1], RATE_PER_SECOND));

        // It should emit 2 {RestartFlowStream} events.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RestartFlowStream({
            streamId: defaultStreamIds[0],
            sender: users.sender,
            ratePerSecond: RATE_PER_SECOND
        });
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RestartFlowStream({
            streamId: defaultStreamIds[1],
            sender: users.sender,
            ratePerSecond: RATE_PER_SECOND
        });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      WITHDRAW
    //////////////////////////////////////////////////////////////////////////*/

    function test_BatchPaybale_Withdraw() external {
        uint256 initialEthBalance = address(flow).balance;

        // Skip forward by one month so that the second stream has also accrued some debt.
        skip(ONE_MONTH);

        depositDefaultAmount(defaultStreamIds[0]);
        depositDefaultAmount(defaultStreamIds[1]);

        // The calldata encoded as a bytes array.
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.withdraw, (defaultStreamIds[0], users.recipient, WITHDRAW_AMOUNT_6D));
        calls[1] = abi.encodeCall(flow.withdraw, (defaultStreamIds[1], users.recipient, WITHDRAW_AMOUNT_6D));

        // It should emit 2 {WithdrawFromFlowStream} events.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.WithdrawFromFlowStream({
            streamId: defaultStreamIds[0],
            to: users.recipient,
            token: usdc,
            caller: users.sender,
            withdrawAmount: WITHDRAW_AMOUNT_6D
        });
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.WithdrawFromFlowStream({
            streamId: defaultStreamIds[1],
            to: users.recipient,
            token: usdc,
            caller: users.sender,
            withdrawAmount: WITHDRAW_AMOUNT_6D
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamIds[1] });

        // It should perform the ERC-20 transfers.
        expectCallToTransfer({ token: usdc, to: users.recipient, value: WITHDRAW_AMOUNT_6D });
        expectCallToTransfer({ token: usdc, to: users.recipient, value: WITHDRAW_AMOUNT_6D });

        // Call the batch function.
        flow.batch{ value: FLOW_MIN_FEE_WEI }(calls);
        assertEq(address(flow).balance, initialEthBalance + FLOW_MIN_FEE_WEI, "lockup contract balance");
    }
}
