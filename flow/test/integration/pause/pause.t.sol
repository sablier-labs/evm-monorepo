// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract Pause_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierV2OpenEnded.pause, (defaultStreamId));
        expectRevertDueToDelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        expectRevertNull();
        openEnded.pause(nullStreamId);
    }

    function test_RevertGiven_Paused() external whenNotDelegateCalled givenNotNull {
        expectRevertPaused();
        openEnded.pause(defaultStreamId);
    }

    function test_RevertWhen_CallerRecipient()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenCallerIsNotTheSender
    {
        resetPrank({ msgSender: users.recipient });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        openEnded.pause(defaultStreamId);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenCallerIsNotTheSender
    {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamId, users.eve)
        );
        openEnded.pause(defaultStreamId);
    }

    function test_Pause_StreamHasDebt()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenCallerIsTheSender
    {
        assertEq(openEnded.refundableAmountOf(defaultStreamId), 0, "refundable amount before pause");
        assertEq(openEnded.withdrawableAmountOf(defaultStreamId), 0, "withdrawable amount before pause");

        openEnded.pause(defaultStreamId);

        assertTrue(openEnded.isPaused(defaultStreamId), "is paused");

        uint128 actualRatePerSecond = openEnded.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        uint128 actualRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);
        uint128 expectedRemainingAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        uint128 actualStreamBalance = openEnded.getBalance(defaultStreamId);
        assertEq(actualStreamBalance, 0, "stream balance");
    }

    function test_Pause()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenCallerIsTheSender
        givenWithdrawableAmountNotZero
        givenRefundableAmountNotZero
    {
        depositToDefaultStream();

        uint128 withdrawableAmount = openEnded.withdrawableAmountOf(defaultStreamId);

        vm.expectEmit({ emitter: address(openEnded) });
        emit PauseOpenEndedStream({
            streamId: defaultStreamId,
            sender: users.sender,
            recipient: users.recipient,
            recipientAmount: withdrawableAmount,
            asset: dai
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        openEnded.pause(defaultStreamId);

        assertTrue(openEnded.isPaused(defaultStreamId), "is paused");

        uint256 actualRatePerSecond = openEnded.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        uint128 actualRemainingAmount = openEnded.getRemainingAmount(defaultStreamId);
        assertEq(actualRemainingAmount, withdrawableAmount, "remaining amount");
    }
}
