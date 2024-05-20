// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract Cancel_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierV2OpenEnded.cancel, (defaultStreamId));
        expectRevertDueToDelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        expectRevertNull();
        openEnded.cancel(nullStreamId);
    }

    function test_RevertGiven_Canceled() external whenNotDelegateCalled givenNotNull {
        expectRevertCanceled();
        openEnded.cancel(defaultStreamId);
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
        openEnded.cancel(defaultStreamId);
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
        openEnded.cancel(defaultStreamId);
    }

    function test_Cancel_WithdrawableAmountZero()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
    {
        assertEq(openEnded.refundableAmountOf(defaultStreamId), 0, "refundable amount before cancel");
        assertEq(openEnded.withdrawableAmountOf(defaultStreamId), 0, "withdrawable amount before cancel");

        openEnded.cancel(defaultStreamId);

        assertTrue(openEnded.isCanceled(defaultStreamId), "is canceled");

        uint128 actualRatePerSecond = openEnded.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        uint128 actualRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);
        assertEq(actualRemainingAmount, 0, "remaining amount");

        uint128 actualStreamBalance = openEnded.getBalance(defaultStreamId);
        assertEq(actualStreamBalance, 0, "stream balance");
    }

    function test_Cancel_RefundableAmountZero()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenWithdrawableAmountNotZero
    {
        openEnded.deposit(defaultStreamId, WITHDRAW_AMOUNT);

        assertEq(openEnded.getBalance(defaultStreamId), WITHDRAW_AMOUNT, "balance before");
        assertEq(openEnded.withdrawableAmountOf(defaultStreamId), WITHDRAW_AMOUNT, "withdrawable amount before cancel");

        openEnded.cancel(defaultStreamId);

        assertTrue(openEnded.isCanceled(defaultStreamId), "is canceled");

        uint128 actualRatePerSecond = openEnded.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        uint128 actualRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);
        uint128 expectedRemainingAmount = WITHDRAW_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        uint128 actualStreamBalance = openEnded.getBalance(defaultStreamId);
        assertEq(actualStreamBalance, 0, "stream balance");
    }

    function test_Cancel_AssetNot18Decimals()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenWithdrawableAmountNotZero
        whenRefundableAmountNotZero
    {
        // Set the timestamp to 1 month ago to create the stream with the same `lastTimeUpdate` as `defaultStreamId`.
        vm.warp({ newTimestamp: WARP_ONE_MONTH - ONE_MONTH });
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        openEnded.deposit(streamId, DEPOSIT_AMOUNT);
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        test_Cancel(streamId, IERC20(address(usdt)));
    }

    function test_Cancel()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenWithdrawableAmountNotZero
        whenRefundableAmountNotZero
    {
        test_Cancel(defaultStreamId, dai);
    }

    function test_Cancel(uint256 streamId, IERC20 asset) internal {
        defaultDeposit();

        uint128 refundableAmount = openEnded.refundableAmountOf(streamId);
        uint128 withdrawableAmount = openEnded.withdrawableAmountOf(streamId);

        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({
            from: address(openEnded),
            to: users.sender,
            value: normalizeTransferAmount(streamId, refundableAmount)
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit CancelOpenEndedStream({
            streamId: streamId,
            sender: users.sender,
            recipient: users.recipient,
            senderAmount: refundableAmount,
            recipientAmount: withdrawableAmount,
            asset: asset
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit MetadataUpdate({ _tokenId: streamId });

        expectCallToTransfer({
            asset: asset,
            to: users.sender,
            amount: normalizeTransferAmount(streamId, refundableAmount)
        });

        openEnded.cancel(streamId);

        assertTrue(openEnded.isCanceled(streamId), "is canceled");

        uint256 actualRatePerSecond = openEnded.getRatePerSecond(streamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        uint128 actualRemainingAmount = openEnded.getRemainingAmount(streamId);
        assertEq(actualRemainingAmount, withdrawableAmount, "remaining amount");

        uint128 actualStreamBalance = openEnded.getBalance(streamId);
        assertEq(actualStreamBalance, 0, "stream balance");
    }
}
