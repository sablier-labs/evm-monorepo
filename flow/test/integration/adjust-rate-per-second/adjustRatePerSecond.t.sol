// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract adjustRatePerSecond_Integration_Test is Integration_Test {
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
        whenratePerSecondNonZero
    {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_RatePerSecondNotDifferent.selector, RATE_PER_SECOND)
        );
        openEnded.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: RATE_PER_SECOND });
    }

    function test_adjustRatePerSecond_WithdrawableAmountZero()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenratePerSecondNonZero
        whenratePerSecondNotDifferent
    {
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        uint128 actualratePerSecond = openEnded.getRatePerSecond(defaultStreamId);
        uint128 expectedratePerSecond = RATE_PER_SECOND;
        assertEq(actualratePerSecond, expectedratePerSecond, "rate per second");

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamId);
        uint40 expectedLastTimeUpdate = uint40(block.timestamp - ONE_MONTH);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 newRatePerSecond = RATE_PER_SECOND / 2;

        vm.expectEmit({ emitter: address(openEnded) });
        emit AdjustOpenEndedStream({
            streamId: defaultStreamId,
            asset: dai,
            recipientAmount: 0,
            oldRatePerSecond: RATE_PER_SECOND,
            newRatePerSecond: newRatePerSecond
        });

        openEnded.adjustRatePerSecond({ streamId: defaultStreamId, newRatePerSecond: newRatePerSecond });

        actualratePerSecond = openEnded.getRatePerSecond(defaultStreamId);
        expectedratePerSecond = newRatePerSecond;
        assertEq(actualratePerSecond, expectedratePerSecond, "rate per second");

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamId);
        expectedLastTimeUpdate = uint40(block.timestamp);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");
    }

    function test_adjustRatePerSecond_AssetNot18Decimals()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
    {
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        test_adjustRatePerSecond(streamId, IERC20(address(usdt)));
    }

    function test_adjustRatePerSecond()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
    {
        test_adjustRatePerSecond(defaultStreamId, dai);
    }

    function test_adjustRatePerSecond(uint256 streamId, IERC20 asset) internal {
        openEnded.deposit(streamId, DEPOSIT_AMOUNT);
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        uint128 actualratePerSecond = openEnded.getRatePerSecond(streamId);
        uint128 expectedratePerSecond = RATE_PER_SECOND;
        assertEq(actualratePerSecond, expectedratePerSecond, "rate per second");

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(streamId);
        uint40 expectedLastTimeUpdate = uint40(block.timestamp - ONE_MONTH);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        vm.expectEmit({ emitter: address(asset) });
        emit Transfer({
            from: address(openEnded),
            to: users.recipient,
            value: normalizeTransferAmount(streamId, ONE_MONTH_STREAMED_AMOUNT)
        });

        uint128 newRatePerSecond = RATE_PER_SECOND / 2;

        vm.expectEmit({ emitter: address(openEnded) });
        emit AdjustOpenEndedStream({
            streamId: streamId,
            asset: asset,
            recipientAmount: ONE_MONTH_STREAMED_AMOUNT,
            oldRatePerSecond: RATE_PER_SECOND,
            newRatePerSecond: newRatePerSecond
        });

        expectCallToTransfer({
            asset: asset,
            to: users.recipient,
            amount: normalizeTransferAmount(streamId, ONE_MONTH_STREAMED_AMOUNT)
        });

        openEnded.adjustRatePerSecond({ streamId: streamId, newRatePerSecond: newRatePerSecond });

        actualratePerSecond = openEnded.getRatePerSecond(streamId);
        expectedratePerSecond = newRatePerSecond;
        assertEq(actualratePerSecond, expectedratePerSecond, "rate per second");

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(streamId);
        expectedLastTimeUpdate = uint40(block.timestamp);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");
    }
}
