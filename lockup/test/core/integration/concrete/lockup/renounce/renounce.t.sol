// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract Renounce_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierLockup.renounce, defaultStreamId);
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Null.selector, nullStreamId));
        lockup.renounce(nullStreamId);
    }

    function test_RevertGiven_DEPLETEDStatus() external whenNoDelegateCall givenNotNull givenColdStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamDepleted.selector, defaultStreamId));
        lockup.renounce(defaultStreamId);
    }

    function test_RevertGiven_CANCELEDStatus() external whenNoDelegateCall givenNotNull givenColdStream {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamCanceled.selector, defaultStreamId));
        lockup.renounce(defaultStreamId);
    }

    function test_RevertGiven_SETTLEDStatus() external whenNoDelegateCall givenNotNull givenColdStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamSettled.selector, defaultStreamId));
        lockup.renounce(defaultStreamId);
    }

    modifier givenWarmStreamRenounce() {
        vm.warp({ newTimestamp: defaults.START_TIME() - 1 seconds });
        _;

        vm.warp({ newTimestamp: defaults.START_TIME() });
        _;
    }

    function test_RevertWhen_CallerNotSender() external whenNoDelegateCall givenNotNull givenWarmStreamRenounce {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Unauthorized.selector, defaultStreamId, users.eve));
        lockup.renounce(defaultStreamId);
    }

    function test_RevertGiven_NonCancelableStream()
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStreamRenounce
        whenCallerSender
    {
        // Create the not cancelable stream.
        uint256 notCancelableStreamId = createDefaultStreamNotCancelable();

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_StreamNotCancelable.selector, notCancelableStreamId)
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
        // Create the stream with a contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(recipientGood));

        // It should emit {MetadataUpdate} and {RenounceLockupStream} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.RenounceLockupStream(streamId);
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        // Renounce the stream.
        lockup.renounce(streamId);

        // It should make stream non cancelable.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }
}
