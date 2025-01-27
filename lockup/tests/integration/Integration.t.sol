// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupDynamic, LockupLinear, LockupTranched } from "src/types/DataTypes.sol";

import { Base_Test } from "../Base.t.sol";
import {
    RecipientInterfaceIDIncorrect,
    RecipientInterfaceIDMissing,
    RecipientInvalidSelector,
    RecipientReentrant,
    RecipientReverting
} from "../mocks/Hooks.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Lockup.Model internal lockupModel;

    // Common stream IDs to be used across the tests.
    // Default stream ID.
    uint256 internal defaultStreamId;
    // A stream with a recipient contract that is not allowed to hook.
    uint256 internal notAllowedtoHookStreamId;
    // A non-cancelable stream ID.
    uint256 internal notCancelableStreamId;
    // A non-transferable stream ID.
    uint256 internal notTransferableStreamId;
    // A stream ID that does not exist.
    uint256 internal nullStreamId = 1729;
    // A stream with a recipient contract that implements {ISablierLockupRecipient}.
    uint256 internal recipientGoodStreamId;
    // A stream with a recipient contract that returns invalid selector bytes on the hook call.
    uint256 internal recipientInvalidSelectorStreamId;
    // A stream with a reentrant contract as the recipient.
    uint256 internal recipientReentrantStreamId;
    // A stream with a reverting contract as the stream's recipient.
    uint256 internal recipientRevertStreamId;

    struct CreateParams {
        Lockup.CreateWithTimestamps createWithTimestamps;
        Lockup.CreateWithDurations createWithDurations;
        uint40 cliffTime;
        LockupLinear.UnlockAmounts unlockAmounts;
        LockupLinear.Durations durations;
        LockupDynamic.Segment[] segments;
        LockupDynamic.SegmentWithDuration[] segmentsWithDurations;
        LockupTranched.Tranche[] tranches;
        LockupTranched.TrancheWithDuration[] tranchesWithDurations;
    }

    CreateParams internal _defaultParams;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    // The following recipients are not allowed to hook.
    RecipientInterfaceIDIncorrect internal recipientInterfaceIDIncorrect;
    RecipientInterfaceIDMissing internal recipientInterfaceIDMissing;

    // The following recipients are allowed to hook.
    RecipientInvalidSelector internal recipientInvalidSelector;
    RecipientReentrant internal recipientReentrant;
    RecipientReverting internal recipientReverting;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Initialize the recipients with Hook implementations.
        initializeRecipientsWithHooks();

        _defaultParams.createWithTimestamps = defaults.createWithTimestamps();
        _defaultParams.createWithDurations = defaults.createWithDurations();
        _defaultParams.cliffTime = defaults.CLIFF_TIME();
        _defaultParams.durations = defaults.durations();
        _defaultParams.unlockAmounts = defaults.unlockAmounts();

        // See https://github.com/ethereum/solidity/issues/12783
        LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations = defaults.segmentsWithDurations();
        LockupDynamic.Segment[] memory segments = defaults.segments();
        for (uint256 i; i < defaults.SEGMENT_COUNT(); ++i) {
            _defaultParams.segments.push(segments[i]);
            _defaultParams.segmentsWithDurations.push(segmentsWithDurations[i]);
        }
        LockupTranched.TrancheWithDuration[] memory tranchesWithDurations = defaults.tranchesWithDurations();
        LockupTranched.Tranche[] memory tranches = defaults.tranches();
        for (uint256 i; i < defaults.TRANCHE_COUNT(); ++i) {
            _defaultParams.tranches.push(tranches[i]);
            _defaultParams.tranchesWithDurations.push(tranchesWithDurations[i]);
        }

        // Set the default Lockup model as Dynamic, we will override the default stream IDs where necessary.
        lockupModel = Lockup.Model.LOCKUP_DYNAMIC;

        // Initialize default streams.
        initializeDefaultStreams();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZE-FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initializeDefaultStreams() internal {
        defaultStreamId = createDefaultStream();
        notAllowedtoHookStreamId = createDefaultStreamWithRecipient(address(recipientInterfaceIDIncorrect));
        notCancelableStreamId = createDefaultStreamNonCancelable();
        notTransferableStreamId = createDefaultStreamNonTransferable();
        recipientGoodStreamId = createDefaultStreamWithRecipient(address(recipientGood));
        recipientInvalidSelectorStreamId = createDefaultStreamWithRecipient(address(recipientInvalidSelector));
        recipientReentrantStreamId = createDefaultStreamWithRecipient(address(recipientReentrant));
        recipientRevertStreamId = createDefaultStreamWithRecipient(address(recipientReverting));
    }

    function initializeRecipientsWithHooks() internal {
        recipientInterfaceIDIncorrect = new RecipientInterfaceIDIncorrect();
        recipientInterfaceIDMissing = new RecipientInterfaceIDMissing();
        recipientInvalidSelector = new RecipientInvalidSelector();
        recipientReentrant = new RecipientReentrant();
        recipientReverting = new RecipientReverting();
        vm.label({ account: address(recipientInterfaceIDIncorrect), newLabel: "Recipient Interface ID Incorrect" });
        vm.label({ account: address(recipientInterfaceIDMissing), newLabel: "Recipient Interface ID Missing" });
        vm.label({ account: address(recipientInvalidSelector), newLabel: "Recipient Invalid Selector" });
        vm.label({ account: address(recipientReentrant), newLabel: "Recipient Reentrant" });
        vm.label({ account: address(recipientReverting), newLabel: "Recipient Reverting" });

        // Allow the selected recipients to hook.
        resetPrank({ msgSender: users.admin });
        lockup.allowToHook(address(recipientGood));
        lockup.allowToHook(address(recipientInvalidSelector));
        lockup.allowToHook(address(recipientReentrant));
        lockup.allowToHook(address(recipientReverting));
        resetPrank({ msgSender: users.sender });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-DEFAULT
    //////////////////////////////////////////////////////////////////////////*/

    function createDefaultStream(Lockup.CreateWithTimestamps memory params) internal returns (uint256 streamId) {
        if (lockupModel == Lockup.Model.LOCKUP_DYNAMIC) {
            streamId = lockup.createWithTimestampsLD(params, _defaultParams.segments);
        } else if (lockupModel == Lockup.Model.LOCKUP_LINEAR) {
            streamId = lockup.createWithTimestampsLL(params, _defaultParams.unlockAmounts, _defaultParams.cliffTime);
        } else if (lockupModel == Lockup.Model.LOCKUP_TRANCHED) {
            streamId = lockup.createWithTimestampsLT(params, _defaultParams.tranches);
        }
    }

    function createDefaultStream() internal returns (uint256 streamId) {
        streamId = createDefaultStream(_defaultParams.createWithTimestamps);
    }

    function createDefaultStreamNonCancelable() internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _defaultParams.createWithTimestamps;
        params.cancelable = false;
        streamId = createDefaultStream(params);
    }

    function createDefaultStreamNonTransferable() internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _defaultParams.createWithTimestamps;
        params.transferable = false;
        streamId = createDefaultStream(params);
    }

    function createDefaultStreamWithDurations() internal returns (uint256 streamId) {
        if (lockupModel == Lockup.Model.LOCKUP_DYNAMIC) {
            streamId =
                lockup.createWithDurationsLD(_defaultParams.createWithDurations, _defaultParams.segmentsWithDurations);
        } else if (lockupModel == Lockup.Model.LOCKUP_LINEAR) {
            streamId = lockup.createWithDurationsLL(
                _defaultParams.createWithDurations, _defaultParams.unlockAmounts, _defaultParams.durations
            );
        } else if (lockupModel == Lockup.Model.LOCKUP_TRANCHED) {
            streamId =
                lockup.createWithDurationsLT(_defaultParams.createWithDurations, _defaultParams.tranchesWithDurations);
        }
    }

    function createDefaultStreamWithEndTime(uint40 endTime) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _defaultParams.createWithTimestamps;
        params.timestamps.end = endTime;
        if (lockupModel == Lockup.Model.LOCKUP_DYNAMIC) {
            LockupDynamic.Segment[] memory segments = _defaultParams.segments;
            segments[1].timestamp = endTime;
            streamId = lockup.createWithTimestampsLD(params, segments);
        } else if (lockupModel == Lockup.Model.LOCKUP_LINEAR) {
            streamId = lockup.createWithTimestampsLL(params, _defaultParams.unlockAmounts, defaults.CLIFF_TIME());
        } else if (lockupModel == Lockup.Model.LOCKUP_TRANCHED) {
            LockupTranched.Tranche[] memory tranches = _defaultParams.tranches;
            tranches[1].timestamp = endTime;
            streamId = lockup.createWithTimestampsLT(params, tranches);
        }
    }

    function createDefaultStreamWithRecipient(address recipient) internal returns (uint256 streamId) {
        streamId = createDefaultStreamWithUsers(recipient, users.sender);
    }

    function createDefaultStreamWithUsers(address recipient, address sender) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _defaultParams.createWithTimestamps;
        params.recipient = recipient;
        params.sender = sender;
        streamId = createDefaultStream(params);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COMMON-REVERT-TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function expectRevert_CallerMaliciousThirdParty(bytes memory callData) internal {
        resetPrank({ msgSender: users.eve });
        (bool success, bytes memory returnData) = address(lockup).call(callData);
        assertFalse(success, "malicious call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierLockupBase_Unauthorized.selector, defaultStreamId, users.eve),
            "malicious call return data"
        );
    }

    function expectRevert_CANCELEDStatus(bytes memory callData) internal {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        lockup.cancel(defaultStreamId);

        (bool success, bytes memory returnData) = address(lockup).call(callData);
        assertFalse(success, "canceled status call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierLockupBase_StreamCanceled.selector, defaultStreamId),
            "canceled status call return data"
        );
    }

    function expectRevert_DelegateCall(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        assertFalse(success, "delegatecall success");
        assertEq(returnData, abi.encodeWithSelector(Errors.DelegateCall.selector), "delegatecall return data");
    }

    function expectRevert_DEPLETEDStatus(bytes memory callData) internal {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        (bool success, bytes memory returnData) = address(lockup).call(callData);
        assertFalse(success, "depleted status call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierLockupBase_StreamDepleted.selector, defaultStreamId),
            "depleted status call return data"
        );
    }

    function expectRevert_Null(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(lockup).call(callData);
        assertFalse(success, "null call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId),
            "null call return data"
        );
    }

    function expectRevert_SETTLEDStatus(bytes memory callData) internal {
        vm.warp({ newTimestamp: defaults.END_TIME() });

        (bool success, bytes memory returnData) = address(lockup).call(callData);
        assertFalse(success, "settled status call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierLockupBase_StreamSettled.selector, defaultStreamId),
            "settled status call return data"
        );
    }
}
