// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Flow } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Batch_Integration_Concrete_Test is Integration_Test {
    uint256[] internal defaultStreamIds;

    function setUp() public override {
        Integration_Test.setUp();
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
        // The calls declared as bytes
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeCall(flow.withdrawMax, (1, users.sender));

        bytes memory expectedRevertData = abi.encodeWithSelector(
            Errors.BatchError.selector,
            abi.encodeWithSelector(
                Errors.SablierFlow_WithdrawalAddressNotRecipient.selector, 1, users.sender, users.sender
            )
        );

        vm.expectRevert(expectedRevertData);
        flow.batch(calls);
    }

    function test_RevertWhen_StringMessage() external {
        uint256 streamId = flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: IERC20(address(usdt)),
            isTransferable: IS_TRANFERABLE
        });

        address noAllowanceAddress = address(0xBEEF);
        resetPrank({ msgSender: noAllowanceAddress });

        uint128 transferAmount = getTransferAmount(TRANSFER_AMOUNT, 6);

        // The calls declared as bytes
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeCall(flow.deposit, (streamId, transferAmount));

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
        calls[0] = abi.encodeCall(flow.refund, (streamId, REFUND_AMOUNT));

        // Remove the ERC20 balance from flow contract.
        deal({ token: address(usdt), to: address(flow), give: 0 });

        vm.expectRevert();
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          ADJUST-RATE-PER-SECOND-MULTIPLE
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_AdjustRatePerSecond() external {
        depositDefaultAmount(defaultStreamIds[0]);
        depositDefaultAmount(defaultStreamIds[1]);

        uint128 newRatePerSecond = RATE_PER_SECOND + 1;

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.adjustRatePerSecond, (defaultStreamIds[0], newRatePerSecond));
        calls[1] = abi.encodeCall(flow.adjustRatePerSecond, (defaultStreamIds[1], newRatePerSecond));

        // It should emit 2 {AdjustRatePerSecond} and 2 {MetadataUpdate} events.

        // First stream to adjust rate per second
        vm.expectEmit({ emitter: address(flow) });
        emit AdjustFlowStream({
            streamId: defaultStreamIds[0],
            amountOwed: ONE_MONTH_STREAMED_AMOUNT,
            newRatePerSecond: newRatePerSecond,
            oldRatePerSecond: RATE_PER_SECOND
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamIds[0] });

        // Second stream to adjust rate per second
        vm.expectEmit({ emitter: address(flow) });
        emit AdjustFlowStream({
            streamId: defaultStreamIds[1],
            amountOwed: ONE_MONTH_STREAMED_AMOUNT,
            newRatePerSecond: newRatePerSecond,
            oldRatePerSecond: RATE_PER_SECOND
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamIds[1] });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  CREATE-MULTIPLE
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_CreateMultiple() external {
        uint256[] memory expectedStreamIds = new uint256[](2);
        expectedStreamIds[0] = flow.nextStreamId();
        expectedStreamIds[1] = expectedStreamIds[0] + 1;

        // The calls declared as bytes
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.create, (users.sender, users.recipient, RATE_PER_SECOND, dai, IS_TRANFERABLE));
        calls[1] = abi.encodeCall(flow.create, (users.sender, users.recipient, RATE_PER_SECOND, dai, IS_TRANFERABLE));

        // It should emit events: 2 {MetadataUpdate}, 2 {CreateFlowStream}

        // First stream to create
        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: expectedStreamIds[0] });

        vm.expectEmit({ emitter: address(flow) });
        emit CreateFlowStream({
            streamId: expectedStreamIds[0],
            asset: dai,
            sender: users.sender,
            recipient: users.recipient,
            lastTimeUpdate: getBlockTimestamp(),
            ratePerSecond: RATE_PER_SECOND
        });

        // Second stream to create
        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: expectedStreamIds[1] });

        vm.expectEmit({ emitter: address(flow) });
        emit CreateFlowStream({
            streamId: expectedStreamIds[1],
            asset: dai,
            sender: users.sender,
            recipient: users.recipient,
            lastTimeUpdate: getBlockTimestamp(),
            ratePerSecond: RATE_PER_SECOND
        });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  DEPOSIT-MULTIPLE
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_DepositMultiple() external {
        // The calls declared as bytes
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.deposit, (defaultStreamIds[0], TRANSFER_AMOUNT));
        calls[1] = abi.encodeCall(flow.deposit, (defaultStreamIds[1], TRANSFER_AMOUNT));

        // It should emit 2 {Transfer}, 2 {DepositFlowStream}, 2 {MetadataUpdate} events.

        // First stream to deposit
        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: users.sender, to: address(flow), value: TRANSFER_AMOUNT });

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({ streamId: defaultStreamIds[0], funder: users.sender, depositAmount: DEPOSIT_AMOUNT });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamIds[0] });

        // Second stream to deposit
        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: users.sender, to: address(flow), value: TRANSFER_AMOUNT });

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({ streamId: defaultStreamIds[1], funder: users.sender, depositAmount: DEPOSIT_AMOUNT });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamIds[1] });

        // It should perform the ERC20 transfers.
        expectCallToTransferFrom({ asset: dai, from: users.sender, to: address(flow), amount: TRANSFER_AMOUNT });
        expectCallToTransferFrom({ asset: dai, from: users.sender, to: address(flow), amount: TRANSFER_AMOUNT });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   PAUSE-MULTIPLE
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_PauseMultiple() external {
        // The calls declared as bytes
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.pause, (defaultStreamIds[0]));
        calls[1] = abi.encodeCall(flow.pause, (defaultStreamIds[1]));

        uint128 previousAmountOwed0 = flow.amountOwedOf(defaultStreamId);
        uint128 previousAmountOwed1 = flow.amountOwedOf(defaultStreamIds[1]);

        // It should emit 2 {PauseFlowStream}, 2 {MetadataUpdate} events.

        // First stream pause
        vm.expectEmit({ emitter: address(flow) });
        emit PauseFlowStream({
            streamId: defaultStreamIds[0],
            recipient: users.recipient,
            sender: users.sender,
            amountOwed: previousAmountOwed0
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamIds[0] });

        // Second stream pause
        vm.expectEmit({ emitter: address(flow) });
        emit PauseFlowStream({
            streamId: defaultStreamIds[1],
            recipient: users.recipient,
            sender: users.sender,
            amountOwed: previousAmountOwed1
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamIds[1] });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  REFUND-MULTIPLE
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_RefundMultiple() external {
        depositDefaultAmount(defaultStreamIds[0]);
        depositDefaultAmount(defaultStreamIds[1]);

        // The calls declared as bytes
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.refund, (defaultStreamIds[0], REFUND_AMOUNT));
        calls[1] = abi.encodeCall(flow.refund, (defaultStreamIds[1], REFUND_AMOUNT));

        // It should emit 2 {Transfer} and 2 {RefundFromFlowStream} events.

        uint128 transferAmount = getTransferAmount(REFUND_AMOUNT, 18);

        // First stream refund
        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: address(flow), to: users.sender, value: transferAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit RefundFromFlowStream({ streamId: defaultStreamIds[0], sender: users.sender, refundAmount: REFUND_AMOUNT });

        // Second stream refund
        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: address(flow), to: users.sender, value: transferAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit RefundFromFlowStream({ streamId: defaultStreamIds[1], sender: users.sender, refundAmount: REFUND_AMOUNT });

        // It should perform the ERC20 transfers.
        expectCallToTransfer({ asset: dai, to: users.sender, amount: transferAmount });
        expectCallToTransfer({ asset: dai, to: users.sender, amount: transferAmount });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  RESTART-MULTIPLE
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_RestartMultiple() external {
        flow.pause({ streamId: defaultStreamIds[0] });
        flow.pause({ streamId: defaultStreamIds[1] });

        // The calls declared as bytes
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.restart, (defaultStreamIds[0], RATE_PER_SECOND));
        calls[1] = abi.encodeCall(flow.restart, (defaultStreamIds[1], RATE_PER_SECOND));

        // It should emit 2 {RestartFlowStream} and 2 {MetadataUpdate} events.

        // First stream restart
        vm.expectEmit({ emitter: address(flow) });
        emit RestartFlowStream({ streamId: defaultStreamIds[0], sender: users.sender, ratePerSecond: RATE_PER_SECOND });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamIds[0] });

        // Second stream restart
        vm.expectEmit({ emitter: address(flow) });
        emit RestartFlowStream({ streamId: defaultStreamIds[1], sender: users.sender, ratePerSecond: RATE_PER_SECOND });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamIds[1] });

        // Call the batch function.
        flow.batch(calls);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 WITHDRAW-MULTIPLE
    //////////////////////////////////////////////////////////////////////////*/

    function test_Batch_WithdrawMultiple() external {
        depositDefaultAmount(defaultStreamIds[0]);
        depositDefaultAmount(defaultStreamIds[1]);

        // The calls declared as bytes
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(flow.withdrawAt, (defaultStreamIds[0], users.recipient, WITHDRAW_TIME));
        calls[1] = abi.encodeCall(flow.withdrawAt, (defaultStreamIds[1], users.recipient, WITHDRAW_TIME));

        uint128 transferAmount = getTransferAmount(WITHDRAW_AMOUNT, 18);

        // It should emit 2 {Transfer}, 2 {WithdrawFromFlowStream} and 2 {MetadataUpdated} events.

        // First stream withdraw
        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: address(flow), to: users.recipient, value: transferAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: defaultStreamIds[0],
            to: users.recipient,
            withdrawnAmount: WITHDRAW_AMOUNT
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamIds[0] });

        // Second stream withdraw
        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: address(flow), to: users.recipient, value: transferAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: defaultStreamIds[1],
            to: users.recipient,
            withdrawnAmount: WITHDRAW_AMOUNT
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamIds[1] });

        // It should perform the ERC20 transfers.
        expectCallToTransfer({ asset: dai, to: users.recipient, amount: transferAmount });
        expectCallToTransfer({ asset: dai, to: users.recipient, amount: transferAmount });

        // Call the batch function.
        flow.batch(calls);
    }
}
