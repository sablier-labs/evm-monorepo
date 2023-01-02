// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SharedTest } from "../SharedTest.t.sol";

abstract contract Renounce__Test is SharedTest {
    uint256 internal defaultStreamId;

    /// @dev it should revert.
    function testCannotRenounce__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2.renounce(nonStreamId);
    }

    modifier StreamExistent() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should revert.
    function testCannotRenounce__CallerNotSender(address eve) external StreamExistent {
        vm.assume(eve != address(0) && eve != users.sender);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamId, eve));
        sablierV2.renounce(defaultStreamId);
    }

    modifier CallerSender() {
        _;
    }

    /// @dev it should revert.
    function testCannotRenounce__NonCancelableStream() external StreamExistent CallerSender {
        // Create the non-cancelable stream.
        uint256 nonCancelableStreamId = createDefaultStreamNonCancelable();

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__RenounceNonCancelableStream.selector, nonCancelableStreamId)
        );
        sablierV2.renounce(nonCancelableStreamId);
    }

    /// @dev it should emit a Renounce event and renounce the stream.
    function testRenounce() external StreamExistent CallerSender {
        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: false });
        emit Events.Renounce(defaultStreamId);

        // Renounce the stream.
        sablierV2.renounce(defaultStreamId);

        // Assert that the stream is non-cancelable now.
        bool isCancelable = sablierV2.isCancelable(defaultStreamId);
        assertFalse(isCancelable);
    }
}
