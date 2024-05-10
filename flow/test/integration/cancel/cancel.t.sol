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

    function test_Cancel_RefundableAmountZero_WithdrawableAmountZero()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
    {
        openEnded.cancel(defaultStreamId);

        assertTrue(openEnded.isCanceled(defaultStreamId), "is canceled");

        uint128 actualStreamBalance = openEnded.getBalance(defaultStreamId);
        assertEq(actualStreamBalance, 0, "stream balance");

        uint256 actualratePerSecond = openEnded.getRatePerSecond(defaultStreamId);
        assertEq(actualratePerSecond, 0, "rate per second");
    }

    function test_Cancel_AssetNot18Decimals()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenCallerAuthorized
        whenRefundAmountNotZero
        whenNoOverrefund
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
        whenRefundAmountNotZero
        whenNoOverrefund
    {
        test_Cancel(defaultStreamId, dai);
    }

    function test_Cancel(uint256 streamId, IERC20 asset) internal {
        defaultDeposit();

        uint128 refundableAmount = openEnded.refundableAmountOf(streamId);
        uint128 withdrawableAmount = openEnded.withdrawableAmountOf(streamId);

        vm.expectEmit({ emitter: address(asset) });
        emit Transfer({
            from: address(openEnded),
            to: users.sender,
            value: normalizeTransferAmount(streamId, refundableAmount)
        });

        vm.expectEmit({ emitter: address(asset) });
        emit Transfer({
            from: address(openEnded),
            to: users.recipient,
            value: normalizeTransferAmount(streamId, withdrawableAmount)
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

        expectCallToTransfer({
            asset: asset,
            to: users.sender,
            amount: normalizeTransferAmount(streamId, refundableAmount)
        });
        expectCallToTransfer({
            asset: asset,
            to: users.recipient,
            amount: normalizeTransferAmount(streamId, withdrawableAmount)
        });
        openEnded.cancel(streamId);

        assertTrue(openEnded.isCanceled(streamId), "is canceled");

        uint128 actualStreamBalance = openEnded.getBalance(streamId);
        assertEq(actualStreamBalance, 0, "stream balance");

        uint256 actualratePerSecond = openEnded.getRatePerSecond(streamId);
        assertEq(actualratePerSecond, 0, "rate per second");
    }
}
