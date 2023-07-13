// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupRecipient } from "src/interfaces/hooks/ISablierV2LockupRecipient.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract Renounce_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) {
        defaultStreamId = createDefaultStream();
    }

    function test_RevertWhen_DelegateCalled() external whenStreamWarm {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.renounce, defaultStreamId);
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    function test_RevertWhen_Null() external whenNotDelegateCalled {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.renounce(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    modifier whenStreamCold() {
        _;
    }

    function test_RevertWhen_StreamCold_StatusDepleted() external whenNotDelegateCalled whenStreamCold {
        vm.warp({ timestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamDepleted.selector, defaultStreamId));
        lockup.renounce(defaultStreamId);
    }

    function test_RevertWhen_StreamCold_StatusCanceled() external whenNotDelegateCalled whenStreamCold {
        vm.warp({ timestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamCanceled.selector, defaultStreamId));
        lockup.renounce(defaultStreamId);
    }

    function test_RevertWhen_StreamCold_StatusSettled() external whenNotDelegateCalled whenStreamCold {
        vm.warp({ timestamp: defaults.END_TIME() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamSettled.selector, defaultStreamId));
        lockup.renounce(defaultStreamId);
    }

    /// @dev This modifier runs the test twice: once with a "PENDING" status, and once with a "STREAMING" status.
    modifier whenStreamWarm() {
        vm.warp({ timestamp: getBlockTimestamp() - 1 seconds });
        _;
        vm.warp({ timestamp: defaults.START_TIME() });
        defaultStreamId = createDefaultStream();
        _;
    }

    function test_RevertWhen_CallerNotSender() external whenNotDelegateCalled whenStreamWarm {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.eve)
        );
        lockup.renounce(defaultStreamId);
    }

    modifier whenCallerSender() {
        _;
    }

    function test_RevertWhen_StreamNotCancelable() external whenNotDelegateCalled whenStreamWarm whenCallerSender {
        // Create the not cancelable stream.
        uint256 notCancelableStreamId = createDefaultStreamNotCancelable();

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCancelable.selector, notCancelableStreamId)
        );
        lockup.renounce(notCancelableStreamId);
    }

    modifier whenStreamCancelable() {
        _;
    }

    function test_Renounce_RecipientNotContract()
        external
        whenNotDelegateCalled
        whenStreamWarm
        whenCallerSender
        whenStreamCancelable
    {
        lockup.renounce(defaultStreamId);
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    modifier whenRecipientContract() {
        _;
    }

    function test_Renounce_RecipientDoesNotImplementHook()
        external
        whenNotDelegateCalled
        whenStreamWarm
        whenCallerSender
        whenStreamCancelable
        whenRecipientContract
    {
        // Create the stream with a no-op contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(noop));

        // Expect a call to the hook.
        vm.expectCall(address(noop), abi.encodeCall(ISablierV2LockupRecipient.onStreamRenounced, (streamId)));

        // Renounce the stream.
        lockup.renounce(streamId);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }

    modifier whenRecipientImplementsHook() {
        _;
    }

    function test_Renounce_RecipientReverts()
        external
        whenNotDelegateCalled
        whenStreamWarm
        whenCallerSender
        whenStreamCancelable
        whenRecipientContract
        whenRecipientImplementsHook
    {
        // Create the stream with a reverting contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));

        // Expect a call to the hook.
        vm.expectCall(
            address(revertingRecipient), abi.encodeCall(ISablierV2LockupRecipient.onStreamRenounced, (streamId))
        );

        // Renounce the stream.
        lockup.renounce(streamId);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }

    modifier whenRecipientDoesNotRevert() {
        _;
    }

    function test_Renounce_RecipientReentrancy()
        external
        whenNotDelegateCalled
        whenStreamWarm
        whenCallerSender
        whenStreamCancelable
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
    {
        // Create the stream with a reentrant contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(reentrantRecipient));

        // Expect a call to the hook.
        vm.expectCall(
            address(reentrantRecipient), abi.encodeCall(ISablierV2LockupRecipient.onStreamRenounced, (streamId))
        );

        // Renounce the stream.
        lockup.renounce(streamId);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }

    modifier whenNoRecipientReentrancy() {
        _;
    }

    function test_Renounce()
        external
        whenNotDelegateCalled
        whenStreamWarm
        whenCallerSender
        whenStreamCancelable
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
        whenNoRecipientReentrancy
    {
        // Create the stream with a contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Expect a call to the hook.
        vm.expectCall(address(goodRecipient), abi.encodeCall(ISablierV2LockupRecipient.onStreamRenounced, (streamId)));

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit RenounceLockupStream(streamId);
        vm.expectEmit({ emitter: address(lockup) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Renounce the stream.
        lockup.renounce(streamId);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }
}
