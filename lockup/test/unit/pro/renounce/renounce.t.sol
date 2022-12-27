// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "src/types/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { ProTest } from "../ProTest.t.sol";

contract Renounce__Test is ProTest {
    uint256 internal defaultStreamId;

    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        defaultStreamId = createDefaultStream();
    }

    /// @dev it should revert.
    function testCannotRenounce__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__StreamNonExistent.selector, nonStreamId));
        pro.renounce(nonStreamId);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should revert.
    function testCannotRenounce__CallerNotSender(address eve) external StreamExistent {
        vm.assume(eve != address(0) && eve != defaultStream.sender);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamId, eve));
        pro.renounce(defaultStreamId);
    }

    modifier CallerSender() {
        _;
    }

    /// @dev it should revert.
    function testCannotRenounce__NonCancelableStream() external StreamExistent CallerSender {
        // Create the non-cancelable stream.
        uint256 streamId = createDefaultStreamNonCancelable();

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__RenounceNonCancelableStream.selector, streamId));
        pro.renounce(streamId);
    }

    /// @dev it should emit a Renounce event and renounce the stream.
    function testRenounce() external StreamExistent CallerSender {
        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: false });
        emit Events.Renounce(defaultStreamId);

        // Renounce the stream.
        pro.renounce(defaultStreamId);

        // Assert that the stream is non-cancelable now.
        bool isCancelable = pro.isCancelable(defaultStreamId);
        assertFalse(isCancelable);
    }
}
