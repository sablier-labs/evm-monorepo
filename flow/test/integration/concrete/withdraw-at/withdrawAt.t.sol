// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract WithdrawAt_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Deposit to the default stream.
        depositToDefaultStream();

        // Set recipient as the caller for this test.
        resetPrank({ msgSender: users.recipient });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.withdrawAt, (defaultStreamId, users.recipient, WITHDRAW_TIME));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.withdrawAt, (nullStreamId, users.recipient, WITHDRAW_TIME));
        expectRevert_Null(callData);
    }

    function test_RevertWhen_TimeLessThanSnapshotTime() external whenNoDelegateCall givenNotNull {
        // Set the snapshot time to the current block timestamp.
        updateSnapshotTimeToBlockTimestamp(defaultStreamId);

        uint40 snapshotTime = flow.getSnapshotTime(defaultStreamId);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_WithdrawTimeLessThanSnapshotTime.selector,
                defaultStreamId,
                snapshotTime,
                WITHDRAW_TIME
            )
        );
        flow.withdrawAt({ streamId: defaultStreamId, to: users.recipient, time: WITHDRAW_TIME });
    }

    function test_RevertWhen_TimeGreaterThanCurrentTime() external whenNoDelegateCall givenNotNull {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_WithdrawalTimeInTheFuture.selector,
                defaultStreamId,
                getBlockTimestamp() + 1,
                getBlockTimestamp()
            )
        );
        flow.withdrawAt({ streamId: defaultStreamId, to: users.recipient, time: getBlockTimestamp() + 1 });
    }

    modifier whenTimeBetweenSnapshotTimeAndCurrentTime() {
        _;
    }

    function test_RevertWhen_WithdrawalAddressZero()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenSnapshotTimeAndCurrentTime
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_WithdrawToZeroAddress.selector, defaultStreamId));
        flow.withdrawAt({ streamId: defaultStreamId, to: address(0), time: WITHDRAW_TIME });
    }

    function test_RevertWhen_CallerSender()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenSnapshotTimeAndCurrentTime
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressNotOwner
    {
        resetPrank({ msgSender: users.sender });

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_WithdrawalAddressNotRecipient.selector, defaultStreamId, users.sender, users.sender
            )
        );
        flow.withdrawAt({ streamId: defaultStreamId, to: users.sender, time: WITHDRAW_TIME });
    }

    function test_RevertWhen_CallerUnknown()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenSnapshotTimeAndCurrentTime
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressNotOwner
    {
        resetPrank({ msgSender: users.eve });

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_WithdrawalAddressNotRecipient.selector, defaultStreamId, users.eve, users.eve
            )
        );
        flow.withdrawAt({ streamId: defaultStreamId, to: users.eve, time: WITHDRAW_TIME });
    }

    function test_WhenCallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenSnapshotTimeAndCurrentTime
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressNotOwner
    {
        // It should withdraw.
        _test_Withdraw({
            streamId: defaultStreamId,
            to: users.eve,
            depositAmount: DEPOSIT_AMOUNT_6D,
            withdrawAmount: WITHDRAW_AMOUNT_6D
        });
    }

    function test_RevertGiven_BalanceZero()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenSnapshotTimeAndCurrentTime
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressIsOwner
    {
        // Go back to the starting point.
        vm.warp({ newTimestamp: MAY_1_2024 });

        // Create a new stream with a deposit of 0.
        uint256 streamId = createDefaultStream();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_WithdrawNoFundsAvailable.selector, streamId));
        flow.withdrawAt({ streamId: streamId, to: users.recipient, time: WITHDRAW_TIME });
    }

    function test_WhenTotalDebtExceedsBalance()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenSnapshotTimeAndCurrentTime
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressIsOwner
        givenBalanceNotZero
    {
        // Go back to the starting point.
        vm.warp({ newTimestamp: MAY_1_2024 });

        resetPrank({ msgSender: users.sender });

        uint128 chickenfeed = 50e6;

        // Create a new stream with a much smaller deposit.
        uint256 streamId = createDefaultStream();
        deposit(streamId, chickenfeed);

        // Simulate the one month of streaming.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // Make recipient the caller for subsequent tests.
        resetPrank({ msgSender: users.recipient });

        // It should withdraw the balance.
        _test_Withdraw({ streamId: streamId, to: users.recipient, depositAmount: chickenfeed, withdrawAmount: 50e6 });
    }

    modifier whenTotalDebtDoesNotExceedBalance() {
        _;
    }

    function test_GivenTokenDoesNotHave18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenSnapshotTimeAndCurrentTime
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressIsOwner
        givenBalanceNotZero
        whenTotalDebtDoesNotExceedBalance
    {
        // It should withdraw the total debt.
        _test_Withdraw({
            streamId: defaultStreamId,
            to: users.recipient,
            depositAmount: DEPOSIT_AMOUNT_6D,
            withdrawAmount: WITHDRAW_AMOUNT_6D
        });
    }

    function test_GivenTokenHas18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenSnapshotTimeAndCurrentTime
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressIsOwner
        givenBalanceNotZero
        whenTotalDebtDoesNotExceedBalance
    {
        // Go back to the starting point.
        vm.warp({ newTimestamp: MAY_1_2024 });

        resetPrank({ msgSender: users.sender });

        // Create the stream and make a deposit.
        uint256 streamId = createDefaultStream(dai);
        deposit(streamId, DEPOSIT_AMOUNT_18D);

        // Simulate the one month of streaming.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // Make recipient the caller for subsequent tests.
        resetPrank({ msgSender: users.recipient });

        // It should withdraw the total debt.
        _test_Withdraw({
            streamId: streamId,
            to: users.recipient,
            depositAmount: DEPOSIT_AMOUNT_18D,
            withdrawAmount: WITHDRAW_AMOUNT_18D
        });
    }

    function _test_Withdraw(uint256 streamId, address to, uint128 depositAmount, uint128 withdrawAmount) private {
        IERC20 token = flow.getToken(streamId);
        uint128 previousFullTotalDebt = flow.totalDebtOf(streamId);

        // It should emit 1 {Transfer}, 1 {WithdrawFromFlowStream} and 1 {MetadataUpdated} events.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: to, value: withdrawAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: streamId,
            to: to,
            token: token,
            caller: users.recipient,
            withdrawAmount: withdrawAmount,
            withdrawTime: WITHDRAW_TIME
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // It should perform the ERC-20 transfer.
        expectCallToTransfer({ token: token, to: to, amount: withdrawAmount });

        uint256 initialTokenBalance = token.balanceOf(address(flow));

        uint128 actualWithdrawAmount = flow.withdrawAt({ streamId: streamId, to: to, time: WITHDRAW_TIME });

        // It should update snapshot time.
        uint128 actualSnapshotTime = flow.getSnapshotTime(streamId);
        assertEq(actualSnapshotTime, WITHDRAW_TIME, "snapshot time");

        // It should decrease the total debt by the withdrawn value.
        uint128 actualFullTotalDebt = flow.totalDebtOf(streamId);
        uint128 expectedFullTotalDebt = previousFullTotalDebt - withdrawAmount;
        assertEq(actualFullTotalDebt, expectedFullTotalDebt, "total debt");

        // It should reduce the stream balance by the withdrawn amount.
        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = depositAmount - withdrawAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // It should reduce the token balance of stream.
        uint256 actualTokenBalance = token.balanceOf(address(flow));
        uint256 expectedTokenBalance = initialTokenBalance - withdrawAmount;
        assertEq(actualTokenBalance, expectedTokenBalance, "token balance");

        // Assert that the returned value equals the transfer value.
        assertEq(actualWithdrawAmount, withdrawAmount);
    }
}
