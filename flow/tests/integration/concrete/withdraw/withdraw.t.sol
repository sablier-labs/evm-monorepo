// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Shared_Integration_Concrete_Test } from "../Concrete.t.sol";

contract Withdraw_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function setUp() public override {
        Shared_Integration_Concrete_Test.setUp();

        // Deposit amount equals to one months of streaming.
        deposit(defaultStreamId, ONE_MONTH_DEBT_6D);

        // Take a snapshot after one month of streaming.
        updateSnapshot(defaultStreamId);

        // Forward time by one more month, so that total debt becomes (2 * ONE_MONTH_DEBT_6D).
        vm.warp({ newTimestamp: getBlockTimestamp() + ONE_MONTH });

        // Set recipient as the caller for this test.
        setMsgSender({ msgSender: users.recipient });
    }

    function test_RevertWhen_DelegateCall() external {
        // It should revert.
        bytes memory callData = abi.encodeCall(flow.withdraw, (defaultStreamId, users.recipient, WITHDRAW_AMOUNT_6D));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        // It should revert.
        bytes memory callData = abi.encodeCall(flow.withdraw, (nullStreamId, users.recipient, WITHDRAW_AMOUNT_6D));
        expectRevert_Null(callData);
    }

    function test_RevertWhen_AmountZero() external whenNoDelegateCall givenNotNull {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_WithdrawAmountZero.selector, defaultStreamId));
        flow.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: 0 });
    }

    function test_RevertWhen_WithdrawalAddressZero() external whenNoDelegateCall givenNotNull whenAmountNotZero {
        // It should revert.
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
        setMsgSender({ msgSender: users.sender });

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_WithdrawalAddressNotRecipient.selector, defaultStreamId, users.sender, users.eve
            )
        );
        flow.withdraw({ streamId: defaultStreamId, to: users.eve, amount: WITHDRAW_AMOUNT_6D });
    }

    function test_RevertWhen_CallerUnknown()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressNotOwner
    {
        setMsgSender({ msgSender: users.eve });

        // It should revert.
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
        _test_Withdraw({ streamId: defaultStreamId, to: users.operator, withdrawAmount: WITHDRAW_AMOUNT_6D });
    }

    modifier whenAuthorizedCaller() {
        // Use recipient as the caller. No need to do anything here since its already set.
        _;

        // Use sender as the caller.
        setMsgSender({ msgSender: users.sender });
        // Forward time by 1 month, take snaphsot and then forward time by 1 more month.
        vm.warp({ newTimestamp: getBlockTimestamp() + ONE_MONTH });
        updateSnapshot(defaultStreamId);
        vm.warp({ newTimestamp: getBlockTimestamp() + ONE_MONTH });
        _;

        // Use operator as the caller.
        setMsgSender({ msgSender: users.operator });
        // Forward time by 1 month, take snaphsot and then forward time by 1 more month.
        vm.warp({ newTimestamp: getBlockTimestamp() + ONE_MONTH });
        updateSnapshot(defaultStreamId);
        vm.warp({ newTimestamp: getBlockTimestamp() + ONE_MONTH });
        _;
    }

    function test_RevertWhen_AmountExceedsBalance()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAuthorizedCaller
        givenBalanceNotExceedTotalDebt
    {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_Overdraw.selector, defaultStreamId, ONE_MONTH_DEBT_6D + 1, ONE_MONTH_DEBT_6D
            )
        );
        flow.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: ONE_MONTH_DEBT_6D + 1 });
    }

    function test_WhenAmountNotExceedBalance()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAuthorizedCaller
        givenBalanceNotExceedTotalDebt
    {
        // It should withdraw.
        _test_Withdraw({ streamId: defaultStreamId, to: users.recipient, withdrawAmount: WITHDRAW_AMOUNT_6D });
    }

    modifier givenBalanceExceedsTotalDebt() override {
        // Deposit so that the stream has surplus balance.
        deposit(defaultStreamId, DEPOSIT_AMOUNT_6D);
        _;
    }

    function test_RevertWhen_AmountGreaterThanTotalDebt()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAuthorizedCaller
        givenBalanceExceedsTotalDebt
    {
        uint128 totalDebt = uint128(flow.totalDebtOf(defaultStreamId));

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFlow_Overdraw.selector, defaultStreamId, totalDebt + 1, totalDebt)
        );
        flow.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: totalDebt + 1 });
    }

    function test_WhenAmountEqualsTotalDebt()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAuthorizedCaller
        givenBalanceExceedsTotalDebt
    {
        uint128 withdrawAmount = uint128(flow.totalDebtOf(defaultStreamId)); // amount = total debt

        // It should make the withdrawal.
        _test_Withdraw({ streamId: defaultStreamId, to: users.recipient, withdrawAmount: withdrawAmount });

        // It should update snapshot debt to zero.
        assertEq(flow.getSnapshotDebtScaled(defaultStreamId), 0, "snapshot debt");
        // It should update snapshot time to current time.
        assertEq(flow.getSnapshotTime(defaultStreamId), getBlockTimestamp(), "snapshot time");
    }

    function test_WhenAmountLessThanSnapshotDebt()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAuthorizedCaller
        givenBalanceExceedsTotalDebt
        whenAmountLessThanTotalDebt
    {
        uint256 initialSnapshotDebt = flow.getSnapshotDebtScaled(defaultStreamId);
        uint40 initialSnapshotTime = flow.getSnapshotTime(defaultStreamId);

        assertTrue(WITHDRAW_AMOUNT_18D < initialSnapshotDebt, "amount < total debt");

        // It should make the withdrawal.
        _test_Withdraw({
            streamId: defaultStreamId,
            to: users.recipient,
            withdrawAmount: WITHDRAW_AMOUNT_6D // amount < snapshot debt => amount < total debt
         });

        // It should reduce snapshot debt by amount withdrawn.
        assertEq(
            flow.getSnapshotDebtScaled(defaultStreamId), initialSnapshotDebt - WITHDRAW_AMOUNT_18D, "snapshot debt"
        );
        // It should not update snapshot time.
        assertEq(flow.getSnapshotTime(defaultStreamId), initialSnapshotTime, "snapshot time");
    }

    function test_WhenAmountEqualsSnapshotDebt()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAuthorizedCaller
        givenBalanceExceedsTotalDebt
        whenAmountLessThanTotalDebt
    {
        uint256 initialSnapshotDebt = getDescaledAmount(flow.getSnapshotDebtScaled(defaultStreamId), 6);
        uint40 initialSnapshotTime = flow.getSnapshotTime(defaultStreamId);
        uint128 withdrawAmount = uint128(initialSnapshotDebt); // amount = snapshot debt

        assertTrue(withdrawAmount < flow.totalDebtOf(defaultStreamId), "amount < total debt");

        // It should make the withdrawal.
        _test_Withdraw({ streamId: defaultStreamId, to: users.recipient, withdrawAmount: withdrawAmount });

        // It should update snapshot debt to zero.
        assertEq(flow.getSnapshotDebtScaled(defaultStreamId), 0, "snapshot debt");
        // It should not update snapshot time.
        assertEq(flow.getSnapshotTime(defaultStreamId), initialSnapshotTime, "snapshot time");
    }

    function test_GivenTokenHas18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAuthorizedCaller
        givenBalanceExceedsTotalDebt
        whenAmountLessThanTotalDebt
        whenAmountGreaterThanSnapshotDebt
    {
        // Go back to the starting point.
        vm.warp({ newTimestamp: FEB_1_2025 });

        // Create the stream and make a deposit.
        uint256 streamId = createDefaultStream(dai);
        deposit(streamId, DEPOSIT_AMOUNT_18D);

        // Simulate the one month of streaming.
        vm.warp({ newTimestamp: ONE_MONTH_SINCE_CREATE });

        // It should make the withdrawal.
        _test_Withdraw({
            streamId: streamId,
            to: users.recipient,
            withdrawAmount: WITHDRAW_AMOUNT_18D // withdrawAmount < total debt and > snapshot debt
         });

        // It should set snapshot debt to difference between total debt and amount withdrawn.
        assertEq(flow.getSnapshotDebtScaled(streamId), ONE_MONTH_DEBT_18D - WITHDRAW_AMOUNT_18D, "snapshot debt");
        // It should update snapshot time to current time
        assertEq(flow.getSnapshotTime(streamId), getBlockTimestamp(), "snapshot time");
    }

    function test_GivenTokenNotHave18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenAmountNotZero
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressOwner
        whenAuthorizedCaller
        givenBalanceExceedsTotalDebt
        whenAmountLessThanTotalDebt
        whenAmountGreaterThanSnapshotDebt
    {
        uint256 initialSnapshotDebt = getDescaledAmount(flow.getSnapshotDebtScaled(defaultStreamId), 6);
        uint256 initalTotalDebt = flow.totalDebtOf(defaultStreamId);
        uint128 withdrawAmount = uint128(initialSnapshotDebt) + WITHDRAW_AMOUNT_6D; // amount > snapshot debt

        assertTrue(withdrawAmount < initalTotalDebt, "amount < total debt");

        // It should make the withdrawal.
        _test_Withdraw({ streamId: defaultStreamId, to: users.recipient, withdrawAmount: withdrawAmount });

        // It should set snapshot debt to difference between total debt and amount withdrawn.
        assertEq(
            flow.getSnapshotDebtScaled(defaultStreamId),
            getScaledAmount(initalTotalDebt - withdrawAmount, 6),
            "snapshot debt"
        );
        // It should update snapshot time to current time
        assertEq(flow.getSnapshotTime(defaultStreamId), getBlockTimestamp(), "snapshot time");
    }

    function _test_Withdraw(uint256 streamId, address to, uint128 withdrawAmount) private {
        vars.token = flow.getToken(streamId);
        vars.previousTokenBalance = vars.token.balanceOf(address(flow));
        vars.previousAggregateAmount = flow.aggregateBalance(vars.token);
        vars.previousStreamBalance = flow.getBalance(streamId);
        vars.previousTotalDebt = flow.totalDebtOf(streamId);

        (, address caller,) = vm.readCallers();

        // It should emit 1 {Transfer}, 1 {WithdrawFromFlowStream} and 1 {MetadataUpdated} events.
        vm.expectEmit({ emitter: address(vars.token) });
        emit IERC20.Transfer({ from: address(flow), to: to, value: withdrawAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.WithdrawFromFlowStream({
            streamId: streamId,
            to: to,
            token: vars.token,
            caller: caller,
            withdrawAmount: withdrawAmount
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        flow.withdraw({ streamId: streamId, to: to, amount: withdrawAmount });

        // It should decrease the total debt by the withdrawn amount requested.
        vars.expectedTotalDebt = vars.previousTotalDebt - withdrawAmount;
        assertEq(flow.totalDebtOf(streamId), vars.expectedTotalDebt, "total debt");

        // It should reduce the stream balance by the withdrawn amount requested.
        vars.expectedStreamBalance = vars.previousStreamBalance - withdrawAmount;
        assertEq(flow.getBalance(streamId), vars.expectedStreamBalance, "stream balance");

        // It should reduce the token balance of stream.
        vars.expectedTokenBalance = vars.previousTokenBalance - withdrawAmount;
        assertEq(vars.token.balanceOf(address(flow)), vars.expectedTokenBalance, "token balance");

        // It should reduce the aggregate amount by the withdrawn amount.
        assertEq(flow.aggregateBalance(vars.token), vars.previousAggregateAmount - withdrawAmount, "aggregate amount");
    }
}
