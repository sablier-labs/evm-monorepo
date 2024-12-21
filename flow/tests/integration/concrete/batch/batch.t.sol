// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";
import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Shared_Integration_Concrete_Test } from "./../Concrete.t.sol";

contract Batch_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    uint256[] internal defaultStreamIds;

    function setUp() public override {
        Shared_Integration_Concrete_Test.setUp();
        defaultStreamIds.push(defaultStreamId);

        // Create a second stream
        vm.warp({ newTimestamp: getBlockTimestamp() - ONE_MONTH });
        defaultStreamIds.push(createDefaultStream());

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       REVERT
    //////////////////////////////////////////////////////////////////////////*/

    function test_RevertWhen_CustomError() external {
        // The calls declared as bytes.
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeCall(flow.withdrawMax, (1, users.recipient));

        bytes memory expectedRevertData = abi.encodeWithSelector(
            Errors.BatchError.selector, abi.encodeWithSelector(Errors.SablierFlow_WithdrawAmountZero.selector, 1)
        );

        vm.expectRevert(expectedRevertData);
        flow.batch(calls);
    }

    function test_RevertWhen_StringMessage() external {
        uint256 streamId = flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            token: IERC20(address(usdt)),
            transferable: TRANSFERABLE
        });

        address noAllowanceAddress = address(0xBEEF);
        resetPrank({ msgSender: noAllowanceAddress });

        // The calls declared as bytes.
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeCall(flow.deposit, (streamId, DEPOSIT_AMOUNT_6D, users.sender, users.recipient));

        bytes memory expectedRevertData = abi.encodeWithSelector(
            Errors.BatchError.selector, abi.encodeWithSignature("Error(string)", "ERC20: insufficient allowance")
        );

        vm.expectRevert(expectedRevertData);
        flow.batch(calls);
    }

    function test_RevertWhen_SilentRevert() external {
        uint256 streamId = createDefaultStream(IERC20(address(usdt)));

        // The calls declared as bytes
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeCall(flow.refund, (streamId, REFUND_AMOUNT_6D));

        // Remove the ERC-20 balance from flow contract.
        deal({ token: address(usdt), to: address(flow), give: 0 });

        vm.expectRevert();
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               ADJUST-RATE-PER-SECOND
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_AdjustRatePerSecond() external {
        depositDefaultAmount(defaultStreamIds[0]);
        depositDefaultAmount(defaultStreamIds[1]);

        UD21x18 newRatePerSecond = ud21x18(RATE_PER_SECOND.unwrap() + 1);

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.adjustRatePerSecond, (defaultStreamIds[0], newRatePerSecond));
        calls[1] = abi.encodeCall(flow.adjustRatePerSecond, (defaultStreamIds[1], newRatePerSecond));

        // It should emit 2 {AdjustRatePerSecond} and 2 {MetadataUpdate} events.

        // First stream to adjust rate per second
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.AdjustFlowStream({
            streamId: defaultStreamIds[0],
            totalDebt: ONE_MONTH_DEBT_6D,
            oldRatePerSecond: RATE_PER_SECOND,
            newRatePerSecond: newRatePerSecond
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamIds[0] });

        // Second stream to adjust rate per second
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.AdjustFlowStream({
            streamId: defaultStreamIds[1],
            totalDebt: ONE_MONTH_DEBT_6D,
            oldRatePerSecond: RATE_PER_SECOND,
            newRatePerSecond: newRatePerSecond
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamIds[1] });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      CREATE
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_Create() external {
        uint256[] memory expectedStreamIds = new uint256[](2);
        expectedStreamIds[0] = flow.nextStreamId();
        expectedStreamIds[1] = flow.nextStreamId() + 1;

        // The calls declared as bytes.
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.create, (users.sender, users.recipient, RATE_PER_SECOND, usdc, TRANSFERABLE));
        calls[1] = abi.encodeCall(flow.create, (users.sender, users.recipient, RATE_PER_SECOND, usdc, TRANSFERABLE));

        // It should emit 2 {MetadataUpdate} and 2 {CreateFlowStream} events.

        // First stream to create.
        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamIds[0] });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.CreateFlowStream({
            streamId: expectedStreamIds[0],
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            token: usdc,
            transferable: TRANSFERABLE
        });

        // Second stream to create.
        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamIds[1] });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.CreateFlowStream({
            streamId: expectedStreamIds[1],
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            token: usdc,
            transferable: TRANSFERABLE
        });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      DEPOSIT
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_Deposit() external {
        // The calls declared as bytes.
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.deposit, (defaultStreamIds[0], DEPOSIT_AMOUNT_6D, users.sender, users.recipient));
        calls[1] = abi.encodeCall(flow.deposit, (defaultStreamIds[1], DEPOSIT_AMOUNT_6D, users.sender, users.recipient));

        // It should emit 2 {Transfer}, 2 {DepositFlowStream}, 2 {MetadataUpdate} events.

        // First stream to deposit.
        vm.expectEmit({ emitter: address(usdc) });
        emit IERC20.Transfer({ from: users.sender, to: address(flow), value: DEPOSIT_AMOUNT_6D });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.DepositFlowStream({
            streamId: defaultStreamIds[0],
            funder: users.sender,
            amount: DEPOSIT_AMOUNT_6D
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamIds[0] });

        // Second stream to deposit.
        vm.expectEmit({ emitter: address(usdc) });
        emit IERC20.Transfer({ from: users.sender, to: address(flow), value: DEPOSIT_AMOUNT_6D });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.DepositFlowStream({
            streamId: defaultStreamIds[1],
            funder: users.sender,
            amount: DEPOSIT_AMOUNT_6D
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamIds[1] });

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({ token: usdc, from: users.sender, to: address(flow), amount: DEPOSIT_AMOUNT_6D });
        expectCallToTransferFrom({ token: usdc, from: users.sender, to: address(flow), amount: DEPOSIT_AMOUNT_6D });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       PAUSE
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_Pause() external {
        // The calls declared as bytes.
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.pause, (defaultStreamIds[0]));
        calls[1] = abi.encodeCall(flow.pause, (defaultStreamIds[1]));

        uint256 previousTotalDebt0 = flow.totalDebtOf(defaultStreamId);
        uint256 previousTotalDebt1 = flow.totalDebtOf(defaultStreamIds[1]);

        // It should emit 2 {PauseFlowStream} and 2 {MetadataUpdate} events.

        // First stream pause.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.PauseFlowStream({
            streamId: defaultStreamIds[0],
            recipient: users.recipient,
            sender: users.sender,
            totalDebt: previousTotalDebt0
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamIds[0] });

        // Second stream pause.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.PauseFlowStream({
            streamId: defaultStreamIds[1],
            sender: users.sender,
            recipient: users.recipient,
            totalDebt: previousTotalDebt1
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamIds[1] });

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

        // It should emit 2 {Transfer} and 2 {RefundFromFlowStream} events.

        // First stream refund.
        vm.expectEmit({ emitter: address(usdc) });
        emit IERC20.Transfer({ from: address(flow), to: users.sender, value: REFUND_AMOUNT_6D });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RefundFromFlowStream({
            streamId: defaultStreamIds[0],
            sender: users.sender,
            amount: REFUND_AMOUNT_6D
        });

        // Second stream refund.
        vm.expectEmit({ emitter: address(usdc) });
        emit IERC20.Transfer({ from: address(flow), to: users.sender, value: REFUND_AMOUNT_6D });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RefundFromFlowStream({
            streamId: defaultStreamIds[1],
            sender: users.sender,
            amount: REFUND_AMOUNT_6D
        });

        // It should perform the ERC-20 transfers.
        expectCallToTransfer({ token: usdc, to: users.sender, amount: REFUND_AMOUNT_6D });
        expectCallToTransfer({ token: usdc, to: users.sender, amount: REFUND_AMOUNT_6D });

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

        // It should emit 2 {RestartFlowStream} and 2 {MetadataUpdate} events.

        // First stream restart.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RestartFlowStream({
            streamId: defaultStreamIds[0],
            sender: users.sender,
            ratePerSecond: RATE_PER_SECOND
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamIds[0] });

        // Second stream restart.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RestartFlowStream({
            streamId: defaultStreamIds[1],
            sender: users.sender,
            ratePerSecond: RATE_PER_SECOND
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamIds[1] });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      WITHDRAW
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_Withdraw() external {
        depositDefaultAmount(defaultStreamIds[0]);
        depositDefaultAmount(defaultStreamIds[1]);

        // The calldata encoded as a bytes array.
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.withdraw, (defaultStreamIds[0], users.recipient, WITHDRAW_AMOUNT_6D));
        calls[1] = abi.encodeCall(flow.withdraw, (defaultStreamIds[1], users.recipient, WITHDRAW_AMOUNT_6D));

        // It should emit 2 {Transfer}, 2 {WithdrawFromFlowStream} and 2 {MetadataUpdated} events.

        // First stream withdrawal.
        vm.expectEmit({ emitter: address(usdc) });
        emit IERC20.Transfer({ from: address(flow), to: users.recipient, value: WITHDRAW_AMOUNT_6D });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.WithdrawFromFlowStream({
            streamId: defaultStreamIds[0],
            to: users.recipient,
            token: usdc,
            caller: users.sender,
            protocolFeeAmount: 0,
            withdrawAmount: WITHDRAW_AMOUNT_6D
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamIds[0] });

        // Second stream withdrawal.
        vm.expectEmit({ emitter: address(usdc) });
        emit IERC20.Transfer({ from: address(flow), to: users.recipient, value: WITHDRAW_AMOUNT_6D });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.WithdrawFromFlowStream({
            streamId: defaultStreamIds[1],
            to: users.recipient,
            token: usdc,
            protocolFeeAmount: 0,
            caller: users.sender,
            withdrawAmount: WITHDRAW_AMOUNT_6D
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamIds[1] });

        // It should perform the ERC-20 transfers.
        expectCallToTransfer({ token: usdc, to: users.recipient, amount: WITHDRAW_AMOUNT_6D });
        expectCallToTransfer({ token: usdc, to: users.recipient, amount: WITHDRAW_AMOUNT_6D });

        // Call the batch function.
        flow.batch(calls);
    }
}
