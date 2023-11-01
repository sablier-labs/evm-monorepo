// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "src/libraries/Errors.sol";
import { OpenEnded } from "src/types/DataTypes.sol";

import { Integration_Test } from "../Integration.t.sol";

contract Withdraw_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        defaultDeposit();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2OpenEnded.withdraw, (defaultStreamId, users.recipient, WITHDRAW_AMOUNT));
        _test_RevertWhen_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        _test_RevertGiven_Null();
        openEnded.withdraw({ streamId: nullStreamId, to: users.recipient, amount: WITHDRAW_AMOUNT });
    }

    function test_RevertGiven_Canceled() external whenNotDelegateCalled givenNotNull {
        _test_RevertGiven_Canceled();
        openEnded.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: WITHDRAW_AMOUNT });
    }

    function test_RevertWhen_CallerUnauthorized_Sender()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerUnauthorized
    {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamId, users.sender)
        );
        openEnded.withdraw({ streamId: defaultStreamId, to: users.sender, amount: WITHDRAW_AMOUNT });
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
        openEnded.withdraw({ streamId: defaultStreamId, to: maliciousThirdParty, amount: WITHDRAW_AMOUNT });
    }

    function test_RevertWhen_ToZeroAddress()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
    {
        changePrank({ msgSender: users.recipient });
        vm.expectRevert(Errors.SablierV2OpenEnded_WithdrawToZeroAddress.selector);
        openEnded.withdraw({ streamId: defaultStreamId, to: address(0), amount: WITHDRAW_AMOUNT });
    }

    function test_RevertWhen_WithdrawAmountZero()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenToNonZeroAddress
    {
        vm.expectRevert(Errors.SablierV2OpenEnded_WithdrawAmountZero.selector);
        openEnded.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: 0 });
    }

    function test_RevertWhen_Overdraw()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_Overdraw.selector,
                defaultStreamId,
                ONE_MONTH_STREAMED_AMOUNT + 1,
                ONE_MONTH_STREAMED_AMOUNT
            )
        );
        openEnded.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: ONE_MONTH_STREAMED_AMOUNT + 1 });
    }

    function test_Withdraw_CallerSender()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
    {
        openEnded.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: WITHDRAW_AMOUNT });
    }

    function test_Withdraw_AssetNot18Decimals()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
    {
        // Set the timestamp to 1 month ago to create the stream with the same `lastTimeUpdate` as `defaultStreamId`.
        vm.warp({ newTimestamp: WARP_ONE_MONTH - ONE_MONTH });
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        openEnded.deposit(streamId, DEPOSIT_AMOUNT);
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        test_Withdraw(streamId, IERC20(address(usdt)));
    }

    function test_Withdraw()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
    {
        test_Withdraw(defaultStreamId, dai);
    }

    function test_Withdraw(uint256 streamId, IERC20 asset) internal {
        changePrank({ msgSender: users.recipient });

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(streamId);
        uint40 expectedLastTimeUpdate = uint40(block.timestamp - ONE_MONTH);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        vm.expectEmit({ emitter: address(asset) });
        emit Transfer({
            from: address(openEnded),
            to: users.recipient,
            value: normalizeTransferAmount(streamId, WITHDRAW_AMOUNT)
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit WithdrawFromOpenEndedStream({
            streamId: streamId,
            to: users.recipient,
            asset: asset,
            amount: WITHDRAW_AMOUNT
        });

        expectCallToTransfer({
            asset: asset,
            to: users.recipient,
            amount: normalizeTransferAmount(streamId, WITHDRAW_AMOUNT)
        });
        openEnded.withdraw({ streamId: streamId, to: users.recipient, amount: WITHDRAW_AMOUNT });

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(streamId);
        expectedLastTimeUpdate = uint40(block.timestamp);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        uint128 actualStreamBalance = openEnded.getBalance(streamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - WITHDRAW_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
