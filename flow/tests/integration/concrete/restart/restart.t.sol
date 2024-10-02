// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Restart_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Pause the stream for this test.
        flow.pause({ streamId: defaultStreamId });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.restart, (defaultStreamId, RATE_PER_SECOND));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.restart, (nullStreamId, RATE_PER_SECOND));
        expectRevert_Null(callData);
    }

    function test_RevertGiven_Voided() external whenNoDelegateCall givenNotNull {
        bytes memory callData = abi.encodeCall(flow.restart, (defaultStreamId, RATE_PER_SECOND));
        expectRevert_Voided(callData);
    }

    function test_RevertWhen_CallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotVoided
        whenCallerNotSender
    {
        bytes memory callData = abi.encodeCall(flow.restart, (defaultStreamId, RATE_PER_SECOND));
        expectRevert_CallerRecipient(callData);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotVoided
        whenCallerNotSender
    {
        bytes memory callData = abi.encodeCall(flow.restart, (defaultStreamId, RATE_PER_SECOND));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_RevertGiven_NotPaused() external whenNoDelegateCall givenNotNull givenNotVoided whenCallerSender {
        uint256 streamId = createDefaultStream();

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_StreamNotPaused.selector, streamId));
        flow.restart({ streamId: streamId, ratePerSecond: RATE_PER_SECOND });
    }

    function test_RevertWhen_NewRatePerSecondZero()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotVoided
        whenCallerSender
        givenPaused
    {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFlow_RatePerSecondNotDifferent.selector, defaultStreamId, ud21x18(0))
        );
        flow.restart({ streamId: defaultStreamId, ratePerSecond: ud21x18(0) });
    }

    function test_WhenNewRatePerSecondNotZero()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotVoided
        whenCallerSender
        givenPaused
    {
        // It should emit 1 {RestartFlowStream}, 1 {MetadataUpdate} event.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RestartFlowStream({
            streamId: defaultStreamId,
            sender: users.sender,
            ratePerSecond: RATE_PER_SECOND
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamId });

        flow.restart({ streamId: defaultStreamId, ratePerSecond: RATE_PER_SECOND });

        bool isPaused = flow.isPaused(defaultStreamId);

        // It should restart the stream.
        assertFalse(isPaused);

        // It should update rate per second.
        UD21x18 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, RATE_PER_SECOND, "ratePerSecond");

        // It should update snapshot time.
        uint40 actualSnapshotTime = flow.getSnapshotTime(defaultStreamId);
        assertEq(actualSnapshotTime, getBlockTimestamp(), "snapshotTime");
    }
}
