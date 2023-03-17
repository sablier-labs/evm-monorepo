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
        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    /// @dev it should revert.
    function test_RevertWhen_DelegateCall() external whenStreamActive {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.renounce, defaultStreamId);
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenStreamNotActive() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external whenNoDelegateCall whenStreamNotActive {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, nullStreamId));
        lockup.renounce(nullStreamId);
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamCanceled() external whenNoDelegateCall whenStreamNotActive {
        lockup.cancel(defaultStreamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, defaultStreamId));
        lockup.renounce(defaultStreamId);
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamDepleted() external whenNoDelegateCall whenStreamNotActive {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, defaultStreamId));
        lockup.renounce(defaultStreamId);
    }

    modifier whenStreamActive() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerNotSender() external whenNoDelegateCall whenStreamActive {
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

    /// @dev it should revert.
    function test_RevertWhen_NonCancelableStream() external whenNoDelegateCall whenStreamActive whenCallerSender {
        // Create the non-cancelable stream.
        uint256 nonCancelableStreamId = createDefaultStreamNonCancelable();

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_RenounceNonCancelableStream.selector, nonCancelableStreamId)
        );
        lockup.renounce(nonCancelableStreamId);
    }

    modifier whenStreamCancelable() {
        _;
    }

    /// @dev it should renounce the stream.
    function test_Renounce_RecipientNotContract()
        external
        whenNoDelegateCall
        whenStreamActive
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

    /// @dev it should renounce the stream, call the recipient hook, and ignore the revert.
    function test_Renounce_RecipientDoesNotImplementHook()
        external
        whenNoDelegateCall
        whenStreamActive
        whenCallerSender
        whenStreamCancelable
        whenRecipientContract
    {
        // Create the stream with an empty contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(empty));

        // Expect a call to the recipient hook.
        vm.expectCall(address(empty), abi.encodeCall(ISablierV2LockupRecipient.onStreamRenounced, (streamId)));

        // Renounce the stream.
        lockup.renounce(streamId);

        // Assert that the stream is non-cancelable.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }

    modifier whenRecipientImplementsHook() {
        _;
    }

    /// @dev it should renounce the stream, call the recipient hook, and ignore the revert.
    function test_Renounce_RecipientReverts()
        external
        whenNoDelegateCall
        whenStreamActive
        whenCallerSender
        whenStreamCancelable
        whenRecipientContract
        whenRecipientImplementsHook
    {
        // Create the stream with a reverting contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(revertingRecipient),
            abi.encodeCall(ISablierV2LockupRecipient.onStreamRenounced, (streamId))
        );

        // Renounce the stream.
        lockup.renounce(streamId);

        // Assert that the stream is non-cancelable.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }

    modifier whenRecipientDoesNotRevert() {
        _;
    }

    /// @dev it should renounce the stream, call the recipient hook, and ignore the revert.
    function test_Renounce_RecipientReentrancy()
        external
        whenNoDelegateCall
        whenStreamActive
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
            address(reentrantRecipient),
            abi.encodeCall(ISablierV2LockupRecipient.onStreamRenounced, (streamId))
        );

        // Renounce the stream.
        lockup.renounce(streamId);

        // Assert that the stream is non-cancelable.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }

    modifier whenNoRecipientReentrancy() {
        _;
    }

    /// @dev it should call the recipient hook, renounce the stream, and emit a {RenounceLockupStream} event.
    function test_Renounce()
        external
        whenNoDelegateCall
        whenStreamActive
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
        vm.expectCall(address(goodRecipient), abi.encodeCall(ISablierV2LockupRecipient.onStreamRenounced, (streamId)));

        // Expect a {RenounceLockupStream} event to be emitted.
        vm.expectEmit();
        emit RenounceLockupStream(streamId);

        // RenounceLockupStream the stream.
        lockup.renounce(streamId);

        // Assert that the stream is non-cancelable now.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }
}
