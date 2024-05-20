// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract AdjustRatePerSecond_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2OpenEnded.adjustRatePerSecond, (defaultStreamId, RATE_PER_SECOND));
        expectRevertDueToDelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        expectRevertNull();
        openEnded.adjustRatePerSecond({ streamId: nullStreamId, newRatePerSecond: RATE_PER_SECOND });
    }

    function test_RevertGiven_Canceled() external whenNotDelegateCalled givenNotNull {
        expectRevertCanceled();
        openEnded.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: RATE_PER_SECOND });
    }

    function test_RevertWhen_CallerUnauthorized_Recipient()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerUnauthorized
    {
        resetPrank({ msgSender: users.recipient });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        openEnded.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: RATE_PER_SECOND });
    }

    function test_RevertWhen_CallerUnauthorized_MaliciousThirdParty()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerUnauthorized
    {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamId, users.eve)
        );
        openEnded.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: RATE_PER_SECOND });
    }

    function test_RevertWhen_ratePerSecondZero()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
    {
        vm.expectRevert(Errors.SablierV2OpenEnded_RatePerSecondZero.selector);
        openEnded.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: 0 });
    }

    function test_RevertWhen_ratePerSecondNotDifferent()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenRatePerSecondNonZero
    {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_RatePerSecondNotDifferent.selector, RATE_PER_SECOND)
        );
        openEnded.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: RATE_PER_SECOND });
    }

    function test_AdjustRatePerSecond_WithdrawableAmountZero()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenRatePerSecondNonZero
        whenRatePerSecondNotDifferent
    {
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamId);
        uint40 expectedLastTimeUpdate = uint40(block.timestamp - ONE_MONTH);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 newRatePerSecond = RATE_PER_SECOND / 2;

        vm.expectEmit({ emitter: address(openEnded) });
        emit AdjustOpenEndedStream({
            streamId: defaultStreamId,
            recipientAmount: 0,
            oldRatePerSecond: RATE_PER_SECOND,
            newRatePerSecond: newRatePerSecond
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        uint128 actualRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);
        uint128 actualStreamBalance = openEnded.getBalance(defaultStreamId);

        assertEq(actualRemainingAmount, 0, "remaining amount");
        assertEq(actualStreamBalance, 0, "stream balance");

        openEnded.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: newRatePerSecond });

        actualRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);
        actualStreamBalance = openEnded.getBalance(defaultStreamId);

        assertEq(actualRemainingAmount, 0, "remaining amount");
        assertEq(actualStreamBalance, 0, "stream balance");

        uint128 actualRatePerSecond = openEnded.getRatePerSecond(defaultStreamId);
        uint128 expectedRatePerSecond = newRatePerSecond;
        assertEq(actualRatePerSecond, expectedRatePerSecond, "rate per second");

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamId);
        expectedLastTimeUpdate = uint40(block.timestamp);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");
    }

    function test_AdjustRatePerSecond()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
    {
        openEnded.deposit(defaultStreamId, DEPOSIT_AMOUNT);
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        uint128 actualRatePerSecond = openEnded.getRatePerSecond(defaultStreamId);
        uint128 expectedRatePerSecond = RATE_PER_SECOND;
        assertEq(actualRatePerSecond, expectedRatePerSecond, "rate per second");

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamId);
        uint40 expectedLastTimeUpdate = uint40(block.timestamp - ONE_MONTH);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 actualRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);
        uint128 expectedRemainingAmount = 0;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        uint128 actualStreamBalance = openEnded.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT;
        assertEq(actualStreamBalance, DEPOSIT_AMOUNT, "stream balance");

        uint128 newRatePerSecond = RATE_PER_SECOND / 2;

        vm.expectEmit({ emitter: address(openEnded) });
        emit AdjustOpenEndedStream({
            streamId: defaultStreamId,
            recipientAmount: ONE_MONTH_STREAMED_AMOUNT,
            oldRatePerSecond: RATE_PER_SECOND,
            newRatePerSecond: newRatePerSecond
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        openEnded.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: newRatePerSecond });

        actualRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);
        expectedRemainingAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        actualStreamBalance = openEnded.getBalance(defaultStreamId);
        expectedStreamBalance = DEPOSIT_AMOUNT - ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        actualRatePerSecond = openEnded.getRatePerSecond(defaultStreamId);
        expectedRatePerSecond = newRatePerSecond;
        assertEq(actualRatePerSecond, expectedRatePerSecond, "rate per second");

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamId);
        expectedLastTimeUpdate = uint40(block.timestamp);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");
    }
}
