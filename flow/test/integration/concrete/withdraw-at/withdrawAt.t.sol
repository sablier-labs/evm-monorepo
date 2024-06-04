// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Helpers } from "src/libraries/Helpers.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract WithdrawAt_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        depositToDefaultStream();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.withdrawAt, (defaultStreamId, users.recipient, WITHDRAW_TIME));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        bytes memory callData = abi.encodeCall(flow.withdrawAt, (nullStreamId, users.recipient, WITHDRAW_TIME));
        expectRevert_Null(callData);
    }

    function test_RevertWhen_ToAddressZero() external whenNotDelegateCalled givenNotNull {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_WithdrawToZeroAddress.selector));
        flow.withdrawAt({ streamId: defaultStreamId, to: address(0), time: WITHDRAW_TIME });
    }

    function test_RevertWhen_CallerSender()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressNotRecipient
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
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressNotRecipient
    {
        address unknownCaller = address(0xCAFE);
        resetPrank({ msgSender: unknownCaller });

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_WithdrawalAddressNotRecipient.selector, defaultStreamId, unknownCaller, unknownCaller
            )
        );

        flow.withdrawAt({ streamId: defaultStreamId, to: unknownCaller, time: WITHDRAW_TIME });
    }

    function test_RevertWhen_WithdrawalTimeLessThanLastTime()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
    {
        uint40 lastTimeUpdate = flow.getLastTimeUpdate(defaultStreamId);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_LastUpdateNotLessThanWithdrawalTime.selector, lastTimeUpdate, lastTimeUpdate - 1
            )
        );
        flow.withdrawAt({ streamId: defaultStreamId, to: users.recipient, time: lastTimeUpdate - 1 });
    }

    function test_RevertWhen_WithdrawalTimeInTheFuture()
        external
        whenNotDelegateCalled
        givenNotNull
        whenWithdrawalTimeNotLessThanLastTime
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
    {
        uint40 futureTime = uint40(block.timestamp + 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_WithdrawalTimeInTheFuture.selector, futureTime, uint40(block.timestamp)
            )
        );
        flow.withdrawAt({ streamId: defaultStreamId, to: users.recipient, time: futureTime });
    }

    function test_RevertGiven_RemainingAmountZero()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenWithdrawalTimeNotLessThanLastTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceZero
    {
        vm.warp({ newTimestamp: WARP_ONE_MONTH - ONE_MONTH });
        uint256 streamId = createDefaultStream();
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_WithdrawNoFundsAvailable.selector, streamId));
        flow.withdrawAt({ streamId: streamId, to: users.recipient, time: WITHDRAW_TIME });
    }

    function test_WithdrawAt_RemainingAmountNotZero()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenWithdrawalTimeNotLessThanLastTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceZero
    {
        vm.warp({ newTimestamp: WARP_ONE_MONTH - ONE_MONTH });
        uint256 streamId = createDefaultStream();
        vm.warp({ newTimestamp: WITHDRAW_TIME });

        flow.deposit(streamId, WITHDRAW_AMOUNT);
        flow.adjustRatePerSecond(streamId, RATE_PER_SECOND - 1);

        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = WITHDRAW_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        uint128 actualRemainingAmount = flow.getRemainingAmount(streamId);
        uint128 expectedRemainingAmount = WITHDRAW_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        flow.withdrawAt({ streamId: streamId, to: users.recipient, time: WITHDRAW_TIME });

        actualRemainingAmount = flow.getRemainingAmount(streamId);
        expectedRemainingAmount = 0;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        actualStreamBalance = flow.getBalance(streamId);
        expectedStreamBalance = 0;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }

    function test_WithdrawAt_CallerSender()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenWithdrawalTimeNotLessThanLastTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceNotZero
        givenRemainingAmountZero
    {
        flow.withdrawAt({ streamId: defaultStreamId, to: users.recipient, time: WITHDRAW_TIME });

        uint40 actualLastTimeUpdate = flow.getLastTimeUpdate(defaultStreamId);
        uint40 expectedLastTimeUpdate = WITHDRAW_TIME;
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - WITHDRAW_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }

    function test_WithdrawAt_CallerUnknown()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenWithdrawalTimeNotLessThanLastTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceNotZero
        givenRemainingAmountZero
    {
        address unknownCaller = address(0xCAFE);
        resetPrank({ msgSender: unknownCaller });

        flow.withdrawAt({ streamId: defaultStreamId, to: users.recipient, time: WITHDRAW_TIME });

        uint40 actualLastTimeUpdate = flow.getLastTimeUpdate(defaultStreamId);
        uint40 expectedLastTimeUpdate = WITHDRAW_TIME;
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - WITHDRAW_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }

    function test_WithdrawAt_StreamPaused()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenWithdrawalTimeNotLessThanLastTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceNotZero
        givenRemainingAmountNotZero
        whenCallerRecipient
    {
        flow.pause(defaultStreamId);

        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        uint128 expectedRemainingAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: address(flow), to: users.recipient, value: ONE_MONTH_STREAMED_AMOUNT });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: defaultStreamId,
            to: users.recipient,
            asset: dai,
            withdrawnAmount: ONE_MONTH_STREAMED_AMOUNT
        });

        expectCallToTransfer({ asset: dai, to: users.recipient, amount: ONE_MONTH_STREAMED_AMOUNT });

        flow.withdrawAt({ streamId: defaultStreamId, to: users.recipient, time: WITHDRAW_TIME });

        actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        expectedRemainingAmount = 0;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");
    }

    function test_WithdrawAt_StreamHasDebt()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenWithdrawalTimeNotLessThanLastTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceNotZero
        givenRemainingAmountNotZero
        whenCallerRecipient
    {
        // Set the timestamp to 1 month ago to create the stream with the same `lastTimeUpdate` as `defaultStreamId`.
        vm.warp({ newTimestamp: WARP_ONE_MONTH - ONE_MONTH });
        uint256 streamId = createDefaultStream();
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        uint128 depositAmount = ONE_MONTH_STREAMED_AMOUNT / 2;
        flow.deposit(streamId, depositAmount);
        flow.adjustRatePerSecond(streamId, RATE_PER_SECOND - 1);

        uint128 actualRemainingAmount = flow.getRemainingAmount(streamId);
        uint128 expectedRemainingAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        flow.withdrawAt({ streamId: streamId, to: users.recipient, time: WARP_ONE_MONTH });

        actualRemainingAmount = flow.getRemainingAmount(streamId);
        expectedRemainingAmount = ONE_MONTH_STREAMED_AMOUNT - depositAmount;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");
    }

    modifier givenNoDebt() {
        _;
    }

    function test_WithdrawAt_AssetNot18Decimals()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenWithdrawalTimeNotLessThanLastTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceNotZero
        whenCallerRecipient
        givenNoDebt
    {
        // Set the timestamp to 1 month ago to create the stream with the same `lastTimeUpdate` as `defaultStreamId`.
        vm.warp({ newTimestamp: WARP_ONE_MONTH - ONE_MONTH });
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        flow.deposit(streamId, TRANSFER_AMOUNT_6D);
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        _test_Withdraw(streamId, IERC20(address(usdt)), 6);
    }

    function test_Withdraw()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenWithdrawalTimeNotLessThanLastTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceNotZero
        whenCallerRecipient
        givenNoDebt
    {
        _test_Withdraw(defaultStreamId, dai, 18);
    }

    function _test_Withdraw(uint256 streamId, IERC20 asset, uint8 assetDecimals) internal {
        resetPrank({ msgSender: users.recipient });

        uint40 actualLastTimeUpdate = flow.getLastTimeUpdate(streamId);
        uint40 expectedLastTimeUpdate = uint40(block.timestamp - ONE_MONTH);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 transferAmount = Helpers.calculateTransferAmount(WITHDRAW_AMOUNT, assetDecimals);

        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({ from: address(flow), to: users.recipient, value: transferAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: streamId,
            to: users.recipient,
            asset: asset,
            withdrawnAmount: WITHDRAW_AMOUNT
        });

        expectCallToTransfer({ asset: asset, to: users.recipient, amount: transferAmount });
        flow.withdrawAt({ streamId: streamId, to: users.recipient, time: WITHDRAW_TIME });

        actualLastTimeUpdate = flow.getLastTimeUpdate(streamId);
        expectedLastTimeUpdate = WITHDRAW_TIME;
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - WITHDRAW_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
