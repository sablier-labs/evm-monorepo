// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Solarray } from "solarray/src/Solarray.sol";

import { ISablierLockupBase } from "src/interfaces/ISablierLockupBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract RenounceMultiple_Integration_Concrete_Test is Integration_Test {
    // An array of stream IDs to be renounces.
    uint256[] internal renounceIds;

    function setUp() public virtual override {
        Integration_Test.setUp();

        // Create test streams.
        renounceIds.push(ids.defaultStream);
        renounceIds.push(createDefaultStream());
    }

    function test_RevertWhen_DelegateCall() external {
        expectRevert_DelegateCall({ callData: abi.encodeCall(lockup.renounceMultiple, renounceIds) });
    }

    function test_WhenZeroArrayLength() external whenNoDelegateCall {
        // It should do nothing.
        uint256[] memory nullIds = new uint256[](0);
        lockup.renounceMultiple(nullIds);
    }

    function test_RevertGiven_AtLeastOneNullStream() external whenNoDelegateCall whenNonZeroArrayLength {
        expectRevert_Null({
            callData: abi.encodeCall(lockup.renounceMultiple, Solarray.uint256s(renounceIds[0], ids.nullStream))
        });
    }

    function test_RevertGiven_AtLeastOneColdStream()
        external
        whenNoDelegateCall
        whenNonZeroArrayLength
        givenNoNullStreams
    {
        uint40 earlyEndTime = defaults.END_TIME() - 10;
        uint256 earlyEndtimeStream = createDefaultStreamWithEndTime(earlyEndTime);
        vm.warp({ newTimestamp: earlyEndTime + 1 seconds });

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_StreamSettled.selector, earlyEndtimeStream));
        lockup.renounceMultiple({ streamIds: Solarray.uint256s(renounceIds[0], earlyEndtimeStream) });
    }

    function test_RevertWhen_CallerUnauthorizedForAny()
        external
        whenNoDelegateCall
        whenNonZeroArrayLength
        givenNoNullStreams
        givenNoColdStreams
    {
        // Make the Recipient the caller in this test.
        setMsgSender(users.recipient);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockupBase_Unauthorized.selector, renounceIds[0], users.recipient)
        );
        lockup.renounceMultiple(renounceIds);
    }

    function test_RevertGiven_AtLeastOneNonCancelableStream()
        external
        whenNoDelegateCall
        whenNonZeroArrayLength
        givenNoNullStreams
        givenNoColdStreams
        whenCallerAuthorizedForAllStreams
    {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockupBase_StreamNotCancelable.selector, ids.notCancelableStream)
        );
        lockup.renounceMultiple({ streamIds: Solarray.uint256s(renounceIds[0], ids.notCancelableStream) });
    }

    function test_GivenAllStreamsCancelable()
        external
        whenNoDelegateCall
        whenNonZeroArrayLength
        givenNoNullStreams
        givenNoColdStreams
        whenCallerAuthorizedForAllStreams
    {
        // It should emit {RenounceLockupStream} events for both streams.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.RenounceLockupStream(renounceIds[0]);
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.RenounceLockupStream(renounceIds[1]);

        // Renounce the streams.
        lockup.renounceMultiple(renounceIds);

        // It should make streams non cancelable.
        assertFalse(lockup.isCancelable(renounceIds[0]), "isCancelable0");
        assertFalse(lockup.isCancelable(renounceIds[1]), "isCancelable1");
    }
}
