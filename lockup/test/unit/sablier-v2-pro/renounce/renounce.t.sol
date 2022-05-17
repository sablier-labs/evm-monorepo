// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__Renounce__UnitTest is SablierV2ProUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();
    }

    /// @dev When the stream does not exist, it should revert.
    function testCannotRenounce__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Pro.renounce(nonStreamId);
    }

    /// @dev When the stream does not exist, it should revert.
    function testCannotRenounce__Unauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        sablierV2Pro.renounce(streamId);
    }

    /// @dev When the stream is already non-cancelable, it should revert.
    function testCannotRenounce__NonCancelabeStream() external {
        // Creaate the non-cancelable stream.
        bool cancelable = false;
        uint256 nonCancelableStreamId = sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            cancelable
        );

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__RenounceNonCancelableStream.selector, nonCancelableStreamId)
        );
        sablierV2Pro.renounce(nonCancelableStreamId);
    }

    /// @dev When all checks pass, it should make the stream non-cancelable.
    function testRenounce() external {
        sablierV2Pro.renounce(streamId);
        ISablierV2Pro.Stream memory stream = sablierV2Pro.getStream(streamId);
        assertEq(stream.cancelable, false);
    }

    /// @dev When all checks pass, it should emit a Renounce event.
    function testRenounce__Event() external {
        vm.expectEmit(true, false, false, false);
        emit Renounce(streamId);
        sablierV2Pro.renounce(streamId);
    }
}
