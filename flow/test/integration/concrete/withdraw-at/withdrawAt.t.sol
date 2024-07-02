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

    function test_RevertWhen_TimeLessThanLastTimeUpdate() external whenNoDelegateCall givenNotNull {
        // Set the last time update to the current block timestamp.
        updateLastTimeToBlockTimestamp(defaultStreamId);

        uint40 lastTimeUpdate = flow.getLastTimeUpdate(defaultStreamId);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_LastUpdateNotLessThanWithdrawalTime.selector,
                defaultStreamId,
                lastTimeUpdate,
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

    modifier whenTimeBetweenLastTimeUpdateAndCurrentTime() {
        _;
    }

    function test_RevertWhen_WithdrawalAddressZero()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenLastTimeUpdateAndCurrentTime
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_WithdrawToZeroAddress.selector, defaultStreamId));
        flow.withdrawAt({ streamId: defaultStreamId, to: address(0), time: WITHDRAW_TIME });
    }

    function test_RevertWhen_CallerSender()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenLastTimeUpdateAndCurrentTime
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
        whenTimeBetweenLastTimeUpdateAndCurrentTime
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
        whenTimeBetweenLastTimeUpdateAndCurrentTime
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressNotOwner
    {
        // It should withdraw.
        _test_Withdraw({
            streamId: defaultStreamId,
            to: users.eve,
            depositedAmount: DEPOSIT_AMOUNT,
            expectedWithdrawAmount: WITHDRAW_AMOUNT
        });
    }

    function test_RevertGiven_BalanceZero()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenLastTimeUpdateAndCurrentTime
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

    function test_WhenAmountOwedExceedsBalance()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenLastTimeUpdateAndCurrentTime
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressIsOwner
        givenBalanceNotZero
    {
        // Go back to the starting point.
        vm.warp({ newTimestamp: MAY_1_2024 });

        resetPrank({ msgSender: users.sender });

        uint128 chickenfeed = 50e18;

        // Create a new stream with very less deposit.
        uint256 streamId = createDefaultStream();
        depositAmount(streamId, chickenfeed);

        // Simulate the one month of streaming.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // Make recipient the caller for subsequent tests.
        resetPrank({ msgSender: users.recipient });

        // It should withdraw the balance.
        _test_Withdraw({
            streamId: streamId,
            to: users.recipient,
            depositedAmount: chickenfeed,
            expectedWithdrawAmount: chickenfeed
        });
    }

    modifier whenAmountOwedDoesNotExceedBalance() {
        _;
    }

    function test_GivenAssetDoesNotHave18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenLastTimeUpdateAndCurrentTime
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressIsOwner
        givenBalanceNotZero
        whenAmountOwedDoesNotExceedBalance
    {
        // Go back to the starting point.
        vm.warp({ newTimestamp: MAY_1_2024 });

        resetPrank({ msgSender: users.sender });
        uint256 streamId = createDefaultStream(IERC20(address(usdc)));
        // Deposit to the stream.
        depositDefaultAmount(streamId);

        // Simulate the one month of streaming.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // Make recipient the caller for subsequent tests.
        resetPrank({ msgSender: users.recipient });

        // It should withdraw the amount owed.
        _test_Withdraw({
            streamId: streamId,
            to: users.recipient,
            depositedAmount: DEPOSIT_AMOUNT,
            expectedWithdrawAmount: WITHDRAW_AMOUNT
        });
    }

    function test_GivenAssetHas18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenTimeBetweenLastTimeUpdateAndCurrentTime
        whenWithdrawalAddressNotZero
        whenWithdrawalAddressIsOwner
        givenBalanceNotZero
        whenAmountOwedDoesNotExceedBalance
    {
        // It should withdraw the amount owed.
        _test_Withdraw({
            streamId: defaultStreamId,
            to: users.recipient,
            depositedAmount: DEPOSIT_AMOUNT,
            expectedWithdrawAmount: WITHDRAW_AMOUNT
        });
    }

    function _test_Withdraw(
        uint256 streamId,
        address to,
        uint128 depositedAmount,
        uint128 expectedWithdrawAmount
    )
        private
    {
        IERC20 asset = flow.getAsset(streamId);
        uint8 assetDecimals = flow.getAssetDecimals(streamId);
        uint128 transferAmount = getTransferAmount(expectedWithdrawAmount, assetDecimals);
        uint128 previousFullAmountOwed = flow.amountOwedOf(defaultStreamId);

        // It should emit 1 {Transfer}, 1 {WithdrawFromFlowStream} and 1 {MetadataUpdated} events.
        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({ from: address(flow), to: to, value: transferAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({ streamId: streamId, to: to, withdrawnAmount: expectedWithdrawAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // It should perform the ERC20 transfer.
        expectCallToTransfer({ asset: asset, to: to, amount: transferAmount });

        uint256 assetBalanceBefore = asset.balanceOf(address(flow));

        uint128 actualTransferAmount = flow.withdrawAt({ streamId: streamId, to: to, time: WITHDRAW_TIME });

        // It should update lastTimeUpdate.
        uint128 actualLastTimeUpdate = flow.getLastTimeUpdate(streamId);
        assertEq(actualLastTimeUpdate, WITHDRAW_TIME, "last time update");

        // It should decrease the full amount owed by withdrawn value.
        uint128 actualFullAmountOwed = flow.amountOwedOf(streamId);
        uint128 expectedFullAmountOwed = previousFullAmountOwed - expectedWithdrawAmount;
        assertEq(actualFullAmountOwed, expectedFullAmountOwed, "full amount owed");

        // It should reduce the stream balance by the withdrawn amount.
        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = depositedAmount - expectedWithdrawAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // It should reduce the asset balance of stream.
        uint256 actualAssetBalance = asset.balanceOf(address(flow));
        uint256 expectedAssetBalance = assetBalanceBefore - transferAmount;
        assertEq(actualAssetBalance, expectedAssetBalance, "asset balance");

        // Assert that the returned value equals the transfer value.
        assertEq(actualTransferAmount, transferAmount);
    }
}
