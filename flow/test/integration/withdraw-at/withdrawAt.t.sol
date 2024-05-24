// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract WithdrawAt_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        depositToDefaultStream();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2OpenEnded.withdrawAt, (defaultStreamId, users.recipient, WITHDRAW_TIME));
        expectRevertDueToDelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        expectRevertNull();
        openEnded.withdrawAt({ streamId: nullStreamId, to: users.recipient, time: WITHDRAW_TIME });
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
                Errors.SablierV2OpenEnded_WithdrawalAddressNotRecipient.selector,
                defaultStreamId,
                unknownCaller,
                unknownCaller
            )
        );

        openEnded.withdrawAt({ streamId: defaultStreamId, to: unknownCaller, time: WITHDRAW_TIME });
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
                Errors.SablierV2OpenEnded_WithdrawalAddressNotRecipient.selector,
                defaultStreamId,
                users.sender,
                users.sender
            )
        );

        openEnded.withdrawAt({ streamId: defaultStreamId, to: users.sender, time: WITHDRAW_TIME });
    }

    function test_RevertWhen_LastTimeNotLessThanWithdrawalTime()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
    {
        uint40 lastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamId);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_LastUpdateNotLessThanWithdrawalTime.selector,
                lastTimeUpdate,
                lastTimeUpdate - 1
            )
        );
        openEnded.withdrawAt({ streamId: defaultStreamId, to: users.recipient, time: lastTimeUpdate - 1 });
    }

    function test_RevertWhen_WithdrawalTimeInTheFuture()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenLastTimeNotLessThanWithdrawalTime
    {
        uint40 futureTime = uint40(block.timestamp + 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_WithdrawalTimeInTheFuture.selector, futureTime, uint40(block.timestamp)
            )
        );
        openEnded.withdrawAt({ streamId: defaultStreamId, to: users.recipient, time: futureTime });
    }

    function test_RevertGiven_BalanceZero()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenLastTimeNotLessThanWithdrawalTime
        whenWithdrawalTimeNotInTheFuture
        givenRemainingAmountZero
    {
        vm.warp({ newTimestamp: WARP_ONE_MONTH - ONE_MONTH });
        uint256 streamId = createDefaultStream();
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2OpenEnded_WithdrawNoFundsAvailable.selector, streamId));
        openEnded.withdrawAt({ streamId: streamId, to: users.recipient, time: WITHDRAW_TIME });
    }

    function test_WithdrawAt_BalanceZero()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenLastTimeNotLessThanWithdrawalTime
        whenWithdrawalTimeNotInTheFuture
        givenRemainingAmountNotZero
    {
        vm.warp({ newTimestamp: WARP_ONE_MONTH - ONE_MONTH });
        uint256 streamId = createDefaultStream();
        vm.warp({ newTimestamp: WITHDRAW_TIME });

        openEnded.deposit(streamId, WITHDRAW_AMOUNT);
        openEnded.adjustRatePerSecond(streamId, RATE_PER_SECOND - 1);

        uint128 actualStreamBalance = openEnded.getBalance(streamId);
        uint128 expectedStreamBalance = WITHDRAW_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        uint128 actualRemainingAmount = openEnded.getRemainingAmount(streamId);
        uint128 expectedRemainingAmount = WITHDRAW_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        openEnded.withdrawAt({ streamId: streamId, to: users.recipient, time: WITHDRAW_TIME });

        actualRemainingAmount = openEnded.getRemainingAmount(streamId);
        expectedRemainingAmount = 0;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        actualStreamBalance = openEnded.getBalance(streamId);
        expectedStreamBalance = 0;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }

    function test_WithdrawAt_CallerSender()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenLastTimeNotLessThanWithdrawalTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceNotZero
        givenRemainingAmountZero
    {
        openEnded.withdrawAt({ streamId: defaultStreamId, to: users.recipient, time: WITHDRAW_TIME });

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamId);
        uint40 expectedLastTimeUpdate = WITHDRAW_TIME;
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 actualStreamBalance = openEnded.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - WITHDRAW_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }

    function test_WithdrawAt_CallerUnknown()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenLastTimeNotLessThanWithdrawalTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceNotZero
        givenRemainingAmountZero
    {
        address unknownCaller = address(0xCAFE);
        resetPrank({ msgSender: unknownCaller });

        openEnded.withdrawAt({ streamId: defaultStreamId, to: users.recipient, time: WITHDRAW_TIME });

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamId);
        uint40 expectedLastTimeUpdate = WITHDRAW_TIME;
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 actualStreamBalance = openEnded.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - WITHDRAW_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }

    function test_WithdrawAt_StreamPaused()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenLastTimeNotLessThanWithdrawalTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceNotZero
        givenRemainingAmountNotZero
        whenCallerRecipient
    {
        openEnded.pause(defaultStreamId);

        uint128 actualRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);
        uint128 expectedRemainingAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: address(openEnded), to: users.recipient, value: ONE_MONTH_STREAMED_AMOUNT });

        vm.expectEmit({ emitter: address(openEnded) });
        emit WithdrawFromOpenEndedStream({
            streamId: defaultStreamId,
            to: users.recipient,
            asset: dai,
            withdrawnAmount: ONE_MONTH_STREAMED_AMOUNT
        });

        expectCallToTransfer({ asset: dai, to: users.recipient, amount: ONE_MONTH_STREAMED_AMOUNT });

        openEnded.withdrawAt({ streamId: defaultStreamId, to: users.recipient, time: WITHDRAW_TIME });

        actualRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);
        expectedRemainingAmount = 0;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");
    }

    function test_WithdrawAt_StreamHasDebt()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenLastTimeNotLessThanWithdrawalTime
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
        openEnded.deposit(streamId, depositAmount);
        openEnded.adjustRatePerSecond(streamId, RATE_PER_SECOND - 1);

        uint128 actualRemainingAmount = openEnded.getRemainingAmount(streamId);
        uint128 expectedRemainingAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        openEnded.withdrawAt({ streamId: streamId, to: users.recipient, time: WARP_ONE_MONTH });

        actualRemainingAmount = openEnded.getRemainingAmount(streamId);
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
        whenLastTimeNotLessThanWithdrawalTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceNotZero
        whenCallerRecipient
        givenNoDebt
    {
        // Set the timestamp to 1 month ago to create the stream with the same `lastTimeUpdate` as `defaultStreamId`.
        vm.warp({ newTimestamp: WARP_ONE_MONTH - ONE_MONTH });
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        openEnded.deposit(streamId, DEPOSIT_AMOUNT);
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        _test_Withdraw(streamId, IERC20(address(usdt)));
    }

    function test_Withdraw()
        external
        whenNotDelegateCalled
        givenNotNull
        whenToNonZeroAddress
        whenWithdrawalAddressIsRecipient
        whenLastTimeNotLessThanWithdrawalTime
        whenWithdrawalTimeNotInTheFuture
        givenBalanceNotZero
        whenCallerRecipient
        givenNoDebt
    {
        _test_Withdraw(defaultStreamId, dai);
    }

    function _test_Withdraw(uint256 streamId, IERC20 asset) internal {
        resetPrank({ msgSender: users.recipient });

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(streamId);
        uint40 expectedLastTimeUpdate = uint40(block.timestamp - ONE_MONTH);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({
            from: address(openEnded),
            to: users.recipient,
            value: normalizeAmountWithStreamId(streamId, WITHDRAW_AMOUNT)
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit WithdrawFromOpenEndedStream({
            streamId: streamId,
            to: users.recipient,
            asset: asset,
            withdrawnAmount: WITHDRAW_AMOUNT
        });

        expectCallToTransfer({
            asset: asset,
            to: users.recipient,
            amount: normalizeAmountWithStreamId(streamId, WITHDRAW_AMOUNT)
        });
        openEnded.withdrawAt({ streamId: streamId, to: users.recipient, time: WITHDRAW_TIME });

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(streamId);
        expectedLastTimeUpdate = WITHDRAW_TIME;
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 actualStreamBalance = openEnded.getBalance(streamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - WITHDRAW_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
