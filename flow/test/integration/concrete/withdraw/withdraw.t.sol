// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Withdraw_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        depositToDefaultStream();

        // Set recipient as the caller for this test.
        resetPrank({ msgSender: users.recipient });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.withdraw, (defaultStreamId, users.recipient, WITHDRAW_TIME));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.withdraw, (nullStreamId, users.recipient, WITHDRAW_TIME));
        expectRevert_Null(callData);
    }

    function test_RevertWhen_AmountZero() external whenNoDelegateCall givenNotNull {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_WithdrawAmountZero.selector, defaultStreamId));
        flow.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: 0 });
    }

    function test_RevertWhen_WithdrawalAddressZero() external whenNoDelegateCall givenNotNull whenAmountNotZero {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_WithdrawToZeroAddress.selector, defaultStreamId));
        flow.withdraw({ streamId: defaultStreamId, to: address(0), amount: WITHDRAW_AMOUNT_6D });
    }

    function test_RevertWhen_CallerSender()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressNotOwner
    {
        resetPrank({ msgSender: users.sender });

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_WithdrawalAddressNotRecipient.selector, defaultStreamId, users.sender, users.sender
            )
        );
        flow.withdraw({ streamId: defaultStreamId, to: users.sender, amount: WITHDRAW_AMOUNT_6D });
    }

    function test_RevertWhen_CallerUnknown()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressNotOwner
    {
        resetPrank({ msgSender: users.eve });

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_WithdrawalAddressNotRecipient.selector, defaultStreamId, users.eve, users.eve
            )
        );
        flow.withdraw({ streamId: defaultStreamId, to: users.eve, amount: WITHDRAW_AMOUNT_6D });
    }

    function test_WhenCallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressNotOwner
    {
        // It should withdraw.
        _test_Withdraw({
            streamId: defaultStreamId,
            to: users.eve,
            depositAmount: DEPOSIT_AMOUNT_6D,
            feeAmount: 0,
            withdrawAmount: WITHDRAW_AMOUNT_6D
        });
    }

    function test_RevertGiven_StreamHasUncoveredDebt()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAmountOverdraws
    {
        // Warp to the moment when stream accumulates uncovered debt.
        vm.warp({ newTimestamp: flow.depletionTimeOf(defaultStreamId) });

        uint128 overdrawAmount = flow.getBalance(defaultStreamId) + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_Overdraw.selector, defaultStreamId, overdrawAmount, overdrawAmount - 1
            )
        );
        flow.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: overdrawAmount });
    }

    function test_RevertGiven_StreamHasNoUncoveredDebt()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAmountOverdraws
    {
        uint128 overdrawAmount = flow.withdrawableAmountOf(defaultStreamId) + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_Overdraw.selector, defaultStreamId, overdrawAmount, overdrawAmount - 1
            )
        );
        flow.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: overdrawAmount });
    }

    function test_WhenAmountNotEqualTotalDebt()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAmountNotOverdraw
    {
        // It should update snapshot debt
        // It should make the withdrawal
        _test_Withdraw({
            streamId: defaultStreamId,
            to: users.recipient,
            depositAmount: DEPOSIT_AMOUNT_6D,
            feeAmount: 0,
            withdrawAmount: flow.totalDebtOf(defaultStreamId) - 1
        });
    }

    function test_GivenProtocolFeeNotZero()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAmountNotOverdraw
        whenAmountEqualTotalDebt
    {
        // Go back to the starting point.
        vm.warp({ newTimestamp: MAY_1_2024 });

        resetPrank({ msgSender: users.sender });

        // Create the stream and make a deposit.
        uint256 streamId = createDefaultStream(tokenWithProtocolFee);
        deposit(streamId, DEPOSIT_AMOUNT_6D);

        // Simulate the one month of streaming.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // Make recipient the caller test.
        resetPrank({ msgSender: users.recipient });

        // It should make the withdrawal.
        _test_Withdraw({
            streamId: streamId,
            to: users.recipient,
            depositAmount: DEPOSIT_AMOUNT_6D,
            feeAmount: PROTOCOL_FEE_AMOUNT_6D,
            withdrawAmount: WITHDRAW_AMOUNT_6D
        });
    }

    function test_GivenTokenHas18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressNotOwner
        whenAmountEqualTotalDebt
        givenProtocolFeeZero
    {
        // Go back to the starting point.
        vm.warp({ newTimestamp: MAY_1_2024 });

        // Create the stream and make a deposit.
        uint256 streamId = createDefaultStream(dai);
        deposit(streamId, DEPOSIT_AMOUNT_18D);

        // Simulate the one month of streaming.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // It should withdraw the total debt.
        _test_Withdraw({
            streamId: streamId,
            to: users.recipient,
            depositAmount: DEPOSIT_AMOUNT_18D,
            feeAmount: 0,
            withdrawAmount: WITHDRAW_AMOUNT_18D
        });
    }

    function test_GivenTokenNotHave18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAmountEqualTotalDebt
        givenProtocolFeeZero
    {
        // It should withdraw the total debt.
        _test_Withdraw({
            streamId: defaultStreamId,
            to: users.recipient,
            depositAmount: DEPOSIT_AMOUNT_6D,
            feeAmount: 0,
            withdrawAmount: WITHDRAW_AMOUNT_6D
        });
    }

    function _test_Withdraw(
        uint256 streamId,
        address to,
        uint128 depositAmount,
        uint128 feeAmount,
        uint128 withdrawAmount
    )
        private
    {
        IERC20 token = flow.getToken(streamId);
        uint128 previousTotalDebt = flow.totalDebtOf(streamId);

        uint128 expectedProtocolRevenue = flow.protocolRevenue(token) + feeAmount;

        // It should emit 1 {Transfer}, 1 {WithdrawFromFlowStream} and 1 {MetadataUpdated} events.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: to, value: withdrawAmount - feeAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: streamId,
            to: to,
            token: token,
            caller: users.recipient,
            protocolFeeAmount: feeAmount,
            withdrawAmount: withdrawAmount - feeAmount
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // It should perform the ERC-20 transfer.
        expectCallToTransfer({ token: token, to: to, amount: withdrawAmount - feeAmount });

        uint256 initialTokenBalance = token.balanceOf(address(flow));

        flow.withdraw({ streamId: streamId, to: to, amount: withdrawAmount });

        // Assert the protocol revenue.
        assertEq(flow.protocolRevenue(token), expectedProtocolRevenue, "protocol revenue");

        // It should update snapshot time.
        assertEq(flow.getSnapshotTime(streamId), getBlockTimestamp(), "snapshot time");

        // It should decrease the total debt by the withdrawn value and fee amount.
        uint128 expectedTotalDebt = previousTotalDebt - withdrawAmount;
        assertEq(flow.totalDebtOf(streamId), expectedTotalDebt, "total debt");

        // It should reduce the stream balance by the withdrawn value and fee amount.
        uint128 expectedStreamBalance = depositAmount - withdrawAmount;
        assertEq(flow.getBalance(streamId), expectedStreamBalance, "stream balance");

        // It should reduce the token balance of stream.
        uint256 expectedTokenBalance = initialTokenBalance - withdrawAmount + feeAmount;
        assertEq(token.balanceOf(address(flow)), expectedTokenBalance, "token balance");
    }
}
