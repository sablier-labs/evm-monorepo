// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Void_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Deposit to the default stream.
        depositToDefaultStream();

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

    function test_RevertGiven_StreamHasNoUncoveredDebt() external whenNoDelegateCall givenNotNull {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_UncoveredDebtZero.selector, defaultStreamId));
        flow.void(defaultStreamId);
    }

    modifier givenStreamHasUncoveredDebt() {
        // Simulate the passage of time to accumulate uncovered debt for one month.
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD + ONE_MONTH });

        _;
    }

    function test_RevertWhen_CallerNotAuthorized()
        external
        whenNoDelegateCall
        givenNotNull
        givenStreamHasUncoveredDebt
    {
        bytes memory callData = abi.encodeCall(flow.void, (defaultStreamId));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_WhenCallerSender()
        external
        whenNoDelegateCall
        givenNotNull
        givenStreamHasUncoveredDebt
        whenCallerAuthorized
    {
        // Make the sender the caller in this test.
        resetPrank({ msgSender: users.sender });

        // It should void the stream.
        _test_Void(users.sender);
    }

    function test_WhenCallerApprovedThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenStreamHasUncoveredDebt
        whenCallerAuthorized
    {
        // Approve the operator to handle the stream.
        flow.approve({ to: users.operator, tokenId: defaultStreamId });

        // Make the operator the caller in this test.
        resetPrank({ msgSender: users.operator });

        // It should void the stream.
        _test_Void(users.operator);
    }

    function test_WhenCallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenStreamHasUncoveredDebt
        whenCallerAuthorized
    {
        // It should void the stream.
        _test_Void(users.recipient);
    }

    function _test_Void(address caller) private {
        uint128 streamBalance = flow.getBalance(defaultStreamId);
        uint128 uncoveredDebt = flow.uncoveredDebtOf(defaultStreamId);

        // It should emit 1 {VoidFlowStream} and 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit VoidFlowStream({
            streamId: defaultStreamId,
            recipient: users.recipient,
            sender: users.sender,
            caller: caller,
            newTotalDebt: streamBalance,
            writtenOffDebt: uncoveredDebt
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        flow.void(defaultStreamId);

        // It should set the rate per second to zero.
        assertEq(flow.getRatePerSecond(defaultStreamId), 0, "rate per second");

        // It should pause the stream.
        assertTrue(flow.isPaused(defaultStreamId), "paused");

        // It should set the total debt to the stream balance.
        assertEq(flow.totalDebtOf(defaultStreamId), streamBalance, "total debt");
    }
}
