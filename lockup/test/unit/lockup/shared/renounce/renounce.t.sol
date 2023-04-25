// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupRecipient } from "src/interfaces/hooks/ISablierV2LockupRecipient.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract Renounce_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        defaultStreamId = createDefaultStream();
    }

    function test_RevertWhen_DelegateCall() external whenStreamWarm {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.renounce, defaultStreamId);
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    function test_RevertWhen_Null() external whenNoDelegateCall {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.renounce(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    modifier whenStreamNotWarm() {
        _;
    }

    function test_RevertWhen_StreamNotWarm_StatusCanceled() external whenNoDelegateCall whenStreamNotWarm {
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME });
        lockup.cancel(defaultStreamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotWarm.selector, defaultStreamId));
        lockup.renounce(defaultStreamId);
    }

    function test_RevertWhen_StreamNotWarm_StatusSettled() external whenNoDelegateCall whenStreamNotWarm {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotWarm.selector, defaultStreamId));
        lockup.renounce(defaultStreamId);
    }

    function test_RevertWhen_StreamNotWarm_StatusDepleted() external whenNoDelegateCall whenStreamNotWarm {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotWarm.selector, defaultStreamId));
        lockup.renounce(defaultStreamId);
    }

    /// @dev This modifier runs the test twice: once with a "PENDING" status, and once with a "STREAMING" status.
    modifier whenStreamWarm() {
        vm.warp({ timestamp: getBlockTimestamp() - 1 seconds });
        _;
        vm.warp({ timestamp: DEFAULT_START_TIME });
        defaultStreamId = createDefaultStream();
        _;
    }

    function test_RevertWhen_CallerNotSender() external whenNoDelegateCall whenStreamWarm {
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

    function test_RevertWhen_StreamNotCancelable() external whenNoDelegateCall whenStreamWarm whenCallerSender {
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
        whenNoDelegateCall
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
        whenNoDelegateCall
        whenStreamWarm
        whenCallerSender
        whenStreamCancelable
        whenRecipientContract
    {
        // Create the stream with an empty contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(empty));

        // Expect a call to the recipient hook.
        vm.expectCall(address(empty), abi.encodeCall(ISablierV2LockupRecipient.onStreamRenounced, (lockup, streamId)));

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
        whenNoDelegateCall
        whenStreamWarm
        whenCallerSender
        whenStreamCancelable
        whenRecipientContract
        whenRecipientImplementsHook
    {
        // Create the stream with a reverting contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(revertingRecipient), abi.encodeCall(ISablierV2LockupRecipient.onStreamRenounced, (lockup, streamId))
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
        whenNoDelegateCall
        whenStreamWarm
        whenCallerSender
        whenStreamCancelable
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
    {
        // Create the stream with a reentrant contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(reentrantRecipient));

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(reentrantRecipient), abi.encodeCall(ISablierV2LockupRecipient.onStreamRenounced, (lockup, streamId))
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
        whenNoDelegateCall
        whenStreamWarm
        whenCallerSender
        whenStreamCancelable
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
        whenNoRecipientReentrancy
    {
        // Create the stream with a contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(goodRecipient), abi.encodeCall(ISablierV2LockupRecipient.onStreamRenounced, (lockup, streamId))
        );

        // Expect a {RenounceLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit RenounceLockupStream(streamId);

        // Renounce the stream.
        lockup.renounce(streamId);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }
}
