// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

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

    function test_RevertGiven_Voided() external whenNoDelegateCall givenNotNull {
        bytes memory callData = abi.encodeCall(flow.void, (defaultStreamId));
        expectRevert_Voided(callData);
    }

    function test_RevertWhen_CallerNotAuthorized() external whenNoDelegateCall givenNotNull givenNotVoided {
        bytes memory callData = abi.encodeCall(flow.void, (defaultStreamId));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_GivenStreamHasNoUncoveredDebt()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotVoided
        whenCallerAuthorized
    {
        // It should void the stream.
        // It should set the rate per second to zero.
        // It should not change the total debt.
        _test_Void(users.recipient);
    }

    modifier givenStreamHasUncoveredDebt() {
        // Simulate the passage of time to accumulate uncovered debt for one month.
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD + ONE_MONTH });

        _;
    }

    function test_WhenCallerSender()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotVoided
        whenCallerAuthorized
        givenStreamHasUncoveredDebt
    {
        // Make the sender the caller in this test.
        resetPrank({ msgSender: users.sender });

        // It should void the stream.
        // It should set the rate per second to zero.
        // It should update the total debt to stream balance.
        _test_Void(users.sender);
    }

    function test_WhenCallerApprovedThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotVoided
        whenCallerAuthorized
        givenStreamHasUncoveredDebt
    {
        // Approve the operator to handle the stream.
        flow.approve({ to: users.operator, tokenId: defaultStreamId });

        // Make the operator the caller in this test.
        resetPrank({ msgSender: users.operator });

        // It should void the stream.
        // It should set the rate per second to zero.
        // It should update the total debt to stream balance.
        _test_Void(users.operator);
    }

    function test_WhenCallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotVoided
        whenCallerAuthorized
        givenStreamHasUncoveredDebt
    {
        // It should void the stream.
        // It should set the rate per second to zero.
        // It should update the total debt to stream balance.
        _test_Void(users.recipient);
    }

    function _test_Void(address caller) private {
        uint256 expectedTotalDebt;
        uint256 uncoveredDebt = flow.uncoveredDebtOf(defaultStreamId);

        if (uncoveredDebt > 0) {
            // Expect the total debt to be stream balance if there is uncovered debt.
            expectedTotalDebt = flow.getBalance(defaultStreamId);
        } else {
            // Otherwise, expect the total debt to remain the same.
            expectedTotalDebt = flow.totalDebtOf(defaultStreamId);
        }

        // It should emit 1 {VoidFlowStream} and 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.VoidFlowStream({
            streamId: defaultStreamId,
            recipient: users.recipient,
            sender: users.sender,
            caller: caller,
            newTotalDebt: expectedTotalDebt,
            writtenOffDebt: uncoveredDebt
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamId });

        flow.void(defaultStreamId);

        // It should set the rate per second to zero.
        assertEq(flow.getRatePerSecond(defaultStreamId), 0, "rate per second");

        // It should pause the stream.
        assertTrue(flow.isPaused(defaultStreamId), "paused");

        // It should void the stream.
        assertTrue(flow.isVoided(defaultStreamId), "voided");

        // Check the new total debt.
        assertEq(flow.totalDebtOf(defaultStreamId), expectedTotalDebt, "total debt");

        // Check the new snapshot time.
        assertEq(flow.getSnapshotTime(defaultStreamId), getBlockTimestamp(), "snapshot time");
    }
}
