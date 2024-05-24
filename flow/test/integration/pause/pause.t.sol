// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract Pause_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierFlow.pause, (defaultStreamId));
        expectRevertDueToDelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        expectRevertNull();
        flow.pause(nullStreamId);
    }

    function test_RevertGiven_Paused() external whenNotDelegateCalled givenNotNull {
        expectRevertPaused();
        flow.pause(defaultStreamId);
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
            abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        flow.pause(defaultStreamId);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenCallerIsNotTheSender
    {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.eve));
        flow.pause(defaultStreamId);
    }

    function test_Pause_StreamHasDebt()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenCallerIsTheSender
    {
        assertEq(flow.refundableAmountOf(defaultStreamId), 0, "refundable amount before pause");
        assertEq(flow.withdrawableAmountOf(defaultStreamId), 0, "withdrawable amount before pause");

        flow.pause(defaultStreamId);

        assertTrue(flow.isPaused(defaultStreamId), "is paused");

        uint128 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        uint128 expectedRemainingAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        assertEq(actualStreamBalance, 0, "stream balance");
    }

    function test_Pause()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenCallerIsTheSender
        givenStreamHasNoDebt
    {
        depositToDefaultStream();

        uint128 withdrawableAmount = flow.withdrawableAmountOf(defaultStreamId);

        vm.expectEmit({ emitter: address(flow) });
        emit PauseFlowStream({
            streamId: defaultStreamId,
            sender: users.sender,
            recipient: users.recipient,
            recipientAmount: withdrawableAmount,
            asset: dai
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        flow.pause(defaultStreamId);

        assertTrue(flow.isPaused(defaultStreamId), "is paused");

        uint256 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        assertEq(actualRemainingAmount, withdrawableAmount, "remaining amount");
    }
}
