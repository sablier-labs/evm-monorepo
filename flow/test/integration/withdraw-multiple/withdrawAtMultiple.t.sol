// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract WithdrawMultiple_Integration_Concrete_Test is Integration_Test {
    uint40[] internal times;

    function setUp() public override {
        Integration_Test.setUp();

        times.push(WITHDRAW_TIME);
        times.push(WITHDRAW_TIME);
        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierV2OpenEnded.withdrawAtMultiple, (defaultStreamIds, times));
        expectRevertDueToDelegateCall(callData);
    }

    function test_RevertWhen_ArrayCountsNotEqual() external whenNotDelegateCalled {
        uint256[] memory streamIds = new uint256[](0);
        uint40[] memory _times = new uint40[](1);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_WithdrawMultipleArrayCountsNotEqual.selector, 0, 1)
        );
        openEnded.withdrawAtMultiple(streamIds, _times);
    }

    modifier whenArrayCountsAreEqual() {
        _;
    }

    function test_WithdrawMultiple_ArrayCountsZero() external whenNotDelegateCalled whenArrayCountsAreEqual {
        uint256[] memory streamIds = new uint256[](0);
        uint40[] memory _times = new uint40[](0);
        openEnded.withdrawAtMultiple(streamIds, _times);
    }

    modifier whenArrayCountsNotZero() {
        _;
    }

    function test_RevertGiven_OnlyNull()
        external
        whenNotDelegateCalled
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
    {
        defaultStreamIds[0] = nullStreamId;
        defaultStreamIds[1] = nullStreamId;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2OpenEnded_Null.selector, nullStreamId));
        openEnded.withdrawAtMultiple({ streamIds: defaultStreamIds, times: times });
    }

    function test_RevertGiven_SomeNull()
        external
        whenNotDelegateCalled
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
    {
        defaultStreamIds[0] = nullStreamId;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2OpenEnded_Null.selector, nullStreamId));
        openEnded.withdrawAtMultiple({ streamIds: defaultStreamIds, times: times });
    }

    function test_RevertGiven_OnlyCanceled()
        external
        whenNotDelegateCalled
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        givenNotNull
    {
        openEnded.cancel(defaultStreamIds[1]);
        expectRevertCanceled();
        openEnded.withdrawAtMultiple({ streamIds: defaultStreamIds, times: times });
    }

    function test_RevertGiven_SomeCanceled()
        external
        whenNotDelegateCalled
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        givenNotNull
    {
        expectRevertCanceled();
        openEnded.withdrawAtMultiple({ streamIds: defaultStreamIds, times: times });
    }

    function test_RevertWhen_OnlyWithdrawalTimesNotGreaterThanLastTimeUpdate()
        external
        whenNotDelegateCalled
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        givenNotNull
        givenNotCanceled
    {
        uint40 lastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamIds[0]);
        times[0] = lastTimeUpdate;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_WithdrawalTimeNotGreaterThanLastUpdate.selector,
                lastTimeUpdate,
                lastTimeUpdate
            )
        );
        openEnded.withdrawAtMultiple({ streamIds: defaultStreamIds, times: times });
    }

    function test_RevertWhen_SomeWithdrawalTimesNotGreaterThanLastTimeUpdate()
        external
        whenNotDelegateCalled
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        givenNotNull
        givenNotCanceled
    {
        uint40 lastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamIds[0]);
        times[0] = lastTimeUpdate;
        times[1] = lastTimeUpdate;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_WithdrawalTimeNotGreaterThanLastUpdate.selector,
                lastTimeUpdate,
                lastTimeUpdate
            )
        );
        openEnded.withdrawAtMultiple({ streamIds: defaultStreamIds, times: times });
    }

    function test_RevertWhen_OnlyWithdrawalTimesInTheFuture()
        external
        whenNotDelegateCalled
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        givenNotNull
        givenNotCanceled
        whenWithdrawalTimeGreaterThanLastUpdate
    {
        uint40 futureTime = uint40(block.timestamp + 1);
        times[0] = futureTime;
        times[1] = futureTime;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_WithdrawalTimeInTheFuture.selector, futureTime, WARP_ONE_MONTH
            )
        );
        openEnded.withdrawAtMultiple({ streamIds: defaultStreamIds, times: times });
    }

    function test_RevertWhen_SomeWithdrawalTimesInTheFuture()
        external
        whenNotDelegateCalled
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        givenNotNull
        givenNotCanceled
        whenWithdrawalTimeGreaterThanLastUpdate
    {
        defaultDeposit();

        uint40 futureTime = uint40(block.timestamp + 1);
        times[1] = futureTime;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_WithdrawalTimeInTheFuture.selector, futureTime, WARP_ONE_MONTH
            )
        );
        openEnded.withdrawAtMultiple({ streamIds: defaultStreamIds, times: times });
    }

    function test_RevertGiven_OnlyZeroBalances()
        external
        whenNotDelegateCalled
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        givenNotNull
        givenNotCanceled
        whenWithdrawalTimeGreaterThanLastUpdate
        whenWithdrawalTimeNotInTheFuture
    {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_WithdrawBalanceZero.selector, defaultStreamIds[0])
        );
        openEnded.withdrawAtMultiple({ streamIds: defaultStreamIds, times: times });
    }

    function test_RevertGiven_SomeZeroBalances()
        external
        whenNotDelegateCalled
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        givenNotNull
        givenNotCanceled
        whenWithdrawalTimeGreaterThanLastUpdate
        whenWithdrawalTimeNotInTheFuture
    {
        defaultDeposit();

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_WithdrawBalanceZero.selector, defaultStreamIds[1])
        );
        openEnded.withdrawAtMultiple({ streamIds: defaultStreamIds, times: times });
    }

    function test_withdrawAtMultiple()
        external
        whenNotDelegateCalled
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        givenNotNull
        givenNotCanceled
        whenWithdrawalTimeGreaterThanLastUpdate
        whenWithdrawalTimeNotInTheFuture
        givenBalanceNotZero
    {
        defaultDeposit();
        defaultDeposit(defaultStreamIds[1]);

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamIds[0]);
        uint40 expectedLastTimeUpdate = uint40(block.timestamp - ONE_MONTH);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamIds[1]);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        vm.expectEmit({ emitter: address(openEnded) });
        emit WithdrawFromOpenEndedStream({
            streamId: defaultStreamIds[0],
            to: users.recipient,
            asset: dai,
            withdrawAmount: WITHDRAW_AMOUNT
        });
        vm.expectEmit({ emitter: address(openEnded) });
        emit WithdrawFromOpenEndedStream({
            streamId: defaultStreamIds[1],
            to: users.recipient,
            asset: dai,
            withdrawAmount: WITHDRAW_AMOUNT
        });

        openEnded.withdrawAtMultiple({ streamIds: defaultStreamIds, times: times });

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamIds[0]);
        expectedLastTimeUpdate = WITHDRAW_TIME;
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamIds[1]);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 actualStreamBalance = openEnded.getBalance(defaultStreamIds[0]);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - WITHDRAW_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        actualStreamBalance = openEnded.getBalance(defaultStreamIds[1]);
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
