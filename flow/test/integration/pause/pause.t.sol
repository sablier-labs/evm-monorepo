// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../Integration.t.sol";

contract Pause_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.pause, (defaultStreamId));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        bytes memory callData = abi.encodeCall(flow.pause, (nullStreamId));
        expectRevert_Null(callData);
    }

    function test_RevertGiven_Paused() external whenNotDelegateCalled givenNotNull {
        bytes memory callData = abi.encodeCall(flow.pause, (defaultStreamId));
        expectRevert_Paused(callData);
    }

    function test_RevertWhen_CallerRecipient()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenCallerIsNotSender
    {
        bytes memory callData = abi.encodeCall(flow.pause, (defaultStreamId));
        expectRevert_CallerRecipient(callData);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenCallerIsNotSender
    {
        bytes memory callData = abi.encodeCall(flow.pause, (defaultStreamId));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_Pause_StreamHasDebt() external whenNotDelegateCalled givenNotNull givenNotPaused whenCallerIsSender {
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
        whenCallerIsSender
        givenStreamHasNoDebt
    {
        depositToDefaultStream();

        uint128 previousAmountOwed = flow.amountOwedOf(defaultStreamId);

        vm.expectEmit({ emitter: address(flow) });
        emit PauseFlowStream({
            streamId: defaultStreamId,
            sender: users.sender,
            recipient: users.recipient,
            amountOwed: previousAmountOwed,
            asset: dai
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        flow.pause(defaultStreamId);

        assertTrue(flow.isPaused(defaultStreamId), "is paused");

        uint256 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        assertEq(actualRemainingAmount, previousAmountOwed, "remaining amount");
    }
}
