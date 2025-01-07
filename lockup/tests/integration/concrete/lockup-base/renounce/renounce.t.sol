// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockupBase } from "src/interfaces/ISablierLockupBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract Renounce_Integration_Concrete_Test is Integration_Test {
    uint256 internal streamId;

    function test_RevertWhen_DelegateCall() external {
        expectRevert_DelegateCall({ callData: abi.encodeCall(lockup.renounce, defaultStreamId) });
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        expectRevert_Null({ callData: abi.encodeCall(lockup.renounce, nullStreamId) });
    }

    function test_RevertGiven_DEPLETEDStatus() external whenNoDelegateCall givenNotNull givenColdStream {
        expectRevert_DEPLETEDStatus({ callData: abi.encodeCall(lockup.renounce, defaultStreamId) });
    }

    function test_RevertGiven_CANCELEDStatus() external whenNoDelegateCall givenNotNull givenColdStream {
        expectRevert_CANCELEDStatus({ callData: abi.encodeCall(lockup.renounce, defaultStreamId) });
    }

    function test_RevertGiven_SETTLEDStatus() external whenNoDelegateCall givenNotNull givenColdStream {
        expectRevert_SETTLEDStatus({ callData: abi.encodeCall(lockup.renounce, defaultStreamId) });
    }

    modifier givenWarmStreamRenounce() {
        vm.warp({ newTimestamp: defaults.START_TIME() - 1 seconds });
        streamId = defaultStreamId;
        _;

        vm.warp({ newTimestamp: defaults.START_TIME() });
        streamId = recipientGoodStreamId;
        _;
    }

    function test_RevertWhen_CallerNotSender() external whenNoDelegateCall givenNotNull givenWarmStreamRenounce {
        expectRevert_CallerMaliciousThirdParty({ callData: abi.encodeCall(lockup.renounce, defaultStreamId) });
    }

    function test_RevertGiven_NonCancelableStream()
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStreamRenounce
        whenCallerSender
    {
        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockupBase_StreamNotCancelable.selector, notCancelableStreamId)
        );
        lockup.renounce(notCancelableStreamId);
    }

    function test_GivenCancelableStream()
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStreamRenounce
        whenCallerSender
    {
        // It should emit {RenounceLockupStream} event.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.RenounceLockupStream(streamId);

        // Renounce the stream.
        lockup.renounce(streamId);

        // It should make stream non cancelable.
        assertFalse(lockup.isCancelable(streamId), "isCancelable");
    }
}
