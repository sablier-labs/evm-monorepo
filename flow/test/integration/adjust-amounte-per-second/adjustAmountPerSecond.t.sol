// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "src/libraries/Errors.sol";
import { OpenEnded } from "src/types/DataTypes.sol";

import { Integration_Test } from "../Integration.t.sol";

contract AdjustAmountPerSecond_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2OpenEnded.adjustAmountPerSecond, (defaultStreamId, AMOUNT_PER_SECOND));
        _test_RevertWhen_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        _test_RevertGiven_Null();
        openEnded.adjustAmountPerSecond({ streamId: nullStreamId, newAmountPerSecond: AMOUNT_PER_SECOND });
    }

    function test_RevertGiven_Canceled() external whenNotDelegateCalled givenNotNull {
        _test_RevertGiven_Canceled();
        openEnded.adjustAmountPerSecond({ streamId: defaultStreamId, newAmountPerSecond: AMOUNT_PER_SECOND });
    }

    function test_RevertWhen_CallerUnauthorized_Recipient()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerUnauthorized
    {
        changePrank({ msgSender: users.recipient });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        openEnded.adjustAmountPerSecond({ streamId: defaultStreamId, newAmountPerSecond: AMOUNT_PER_SECOND });
    }

    function test_RevertWhen_CallerUnauthorized_MaliciousThirdParty(address maliciousThirdParty)
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerUnauthorized
    {
        vm.assume(maliciousThirdParty != users.sender && maliciousThirdParty != users.recipient);
        changePrank({ msgSender: maliciousThirdParty });
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamId, maliciousThirdParty
            )
        );
        openEnded.adjustAmountPerSecond({ streamId: defaultStreamId, newAmountPerSecond: AMOUNT_PER_SECOND });
    }

    function test_RevertWhen_AmountPerSecondZero()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
    {
        vm.expectRevert(Errors.SablierV2OpenEnded_AmountPerSecondZero.selector);
        openEnded.adjustAmountPerSecond({ streamId: defaultStreamId, newAmountPerSecond: 0 });
    }

    function test_RevertWhen_AmountPerSecondNotDifferent()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenAmountPerSecondNonZero
    {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_AmountPerSecondNotDifferent.selector, AMOUNT_PER_SECOND)
        );
        openEnded.adjustAmountPerSecond({ streamId: defaultStreamId, newAmountPerSecond: AMOUNT_PER_SECOND });
    }

    function test_AdjustAmountPerSecond_WithdrawableAmountZero()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenAmountPerSecondNonZero
        whenAmountPerSecondNotDifferent
    {
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        uint128 actualAmountPerSecond = openEnded.getAmountPerSecond(defaultStreamId);
        uint128 expectedAmountPerSecond = AMOUNT_PER_SECOND;
        assertEq(actualAmountPerSecond, expectedAmountPerSecond, "amount per second");

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamId);
        uint40 expectedLastTimeUpdate = uint40(block.timestamp - ONE_MONTH);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 newAmountPerSecond = AMOUNT_PER_SECOND / 2;

        vm.expectEmit({ emitter: address(openEnded) });
        emit AdjustOpenEndedStream({
            streamId: defaultStreamId,
            asset: dai,
            recipientAmount: 0,
            oldAmountPerSecond: AMOUNT_PER_SECOND,
            newAmountPerSecond: newAmountPerSecond
        });

        openEnded.adjustAmountPerSecond({ streamId: defaultStreamId, newAmountPerSecond: newAmountPerSecond });

        actualAmountPerSecond = openEnded.getAmountPerSecond(defaultStreamId);
        expectedAmountPerSecond = newAmountPerSecond;
        assertEq(actualAmountPerSecond, expectedAmountPerSecond, "amount per second");

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamId);
        expectedLastTimeUpdate = uint40(block.timestamp);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");
    }

    function test_AdjustAmountPerSecond_AssetNot18Decimals()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
    {
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        test_AdjustAmountPerSecond(streamId, IERC20(address(usdt)));
    }

    function test_AdjustAmountPerSecond()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
    {
        test_AdjustAmountPerSecond(defaultStreamId, dai);
    }

    function test_AdjustAmountPerSecond(uint256 streamId, IERC20 asset) internal {
        openEnded.deposit(streamId, DEPOSIT_AMOUNT);
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        uint128 actualAmountPerSecond = openEnded.getAmountPerSecond(streamId);
        uint128 expectedAmountPerSecond = AMOUNT_PER_SECOND;
        assertEq(actualAmountPerSecond, expectedAmountPerSecond, "amount per second");

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(streamId);
        uint40 expectedLastTimeUpdate = uint40(block.timestamp - ONE_MONTH);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        vm.expectEmit({ emitter: address(asset) });
        emit Transfer({
            from: address(openEnded),
            to: users.recipient,
            value: normalizeTransferAmount(streamId, ONE_MONTH_STREAMED_AMOUNT)
        });

        uint128 newAmountPerSecond = AMOUNT_PER_SECOND / 2;

        vm.expectEmit({ emitter: address(openEnded) });
        emit AdjustOpenEndedStream({
            streamId: streamId,
            asset: asset,
            recipientAmount: ONE_MONTH_STREAMED_AMOUNT,
            oldAmountPerSecond: AMOUNT_PER_SECOND,
            newAmountPerSecond: newAmountPerSecond
        });

        expectCallToTransfer({
            asset: asset,
            to: users.recipient,
            amount: normalizeTransferAmount(streamId, ONE_MONTH_STREAMED_AMOUNT)
        });

        openEnded.adjustAmountPerSecond({ streamId: streamId, newAmountPerSecond: newAmountPerSecond });

        actualAmountPerSecond = openEnded.getAmountPerSecond(streamId);
        expectedAmountPerSecond = newAmountPerSecond;
        assertEq(actualAmountPerSecond, expectedAmountPerSecond, "amount per second");

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(streamId);
        expectedLastTimeUpdate = uint40(block.timestamp);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");
    }
}
