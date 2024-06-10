// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Void_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Deposit to the default stream.
        depositDefaultAmountToDefaultStream();

        // Make the recipient the caller in this tests.
        resetPrank({ msgSender: users.recipient });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.void, (defaultStreamId));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.void, (nullStreamId));
        expectRevert_Null(callData);
    }

    function test_RevertGiven_StreamHasNoDebt() external whenNoDelegateCall givenNotNull {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_DebtZero.selector, defaultStreamId));
        flow.void(defaultStreamId);
    }

    modifier givenStreamHasDebt() {
        // Simulate the passage of time to accumulate debt for one month.
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD + ONE_MONTH });

        _;
    }

    function test_RevertWhen_CallerSender()
        external
        whenNoDelegateCall
        givenNotNull
        givenStreamHasDebt
        whenCallerNotRecipient
    {
        bytes memory callData = abi.encodeCall(flow.void, (defaultStreamId));
        expectRevert_CallerSender(callData);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenStreamHasDebt
        whenCallerNotRecipient
    {
        bytes memory callData = abi.encodeCall(flow.void, (defaultStreamId));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_WhenCallerApprovedThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenStreamHasDebt
        whenCallerNotRecipient
    {
        // Approve the operator to handle the stream.
        flow.approve({ to: users.operator, tokenId: defaultStreamId });

        // Make the operator the caller in this test.
        resetPrank({ msgSender: users.operator });

        // It should void the stream.
        _test_Void();
    }

    function test_WhenCallerRecipient() external whenNoDelegateCall givenNotNull givenStreamHasDebt {
        // It should void the stream.
        _test_Void();
    }

    function _test_Void() private {
        uint128 streamBalance = flow.getBalance(defaultStreamId);
        uint128 debt = flow.streamDebtOf(defaultStreamId);

        // It should emit 1 {VoidFlowStream}, 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit VoidFlowStream({
            streamId: defaultStreamId,
            recipient: users.recipient,
            sender: users.sender,
            newAmountOwed: streamBalance,
            writenoffDebt: debt
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        flow.void(defaultStreamId);

        // It should set the rate per second to zero.
        assertEq(flow.getRatePerSecond(defaultStreamId), 0, "rate per second");

        // It should pause the stream.
        assertTrue(flow.isPaused(defaultStreamId), "paused");

        // It should update the amount owed to stream balance.
        assertEq(flow.amountOwedOf(defaultStreamId), streamBalance, "amount owed");
    }
}
