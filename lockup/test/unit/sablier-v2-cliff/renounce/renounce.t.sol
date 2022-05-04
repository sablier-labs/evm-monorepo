// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__Renounce__UnitTest is SablierV2CliffUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultCliffStream();
    }

    /// @dev When the cliff stream does not exist, it should revert.
    function testCannotRenounce__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Cliff.renounce(nonStreamId);
    }

    /// @dev When the cliff stream does not exist, it should revert.
    function testCannotRenounce__Unauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        sablierV2Cliff.renounce(streamId);
    }

    /// @dev When the cliff stream is already non-cancelable, it should revert.
    function testCannotRenounce__NonCancelabeStream() external {
        // Creaate the non-cancelable stream.
        bool cancelable = false;
        uint256 nonCancelableStreamId = sablierV2Cliff.create(
            cliffStream.sender,
            cliffStream.recipient,
            cliffStream.depositAmount,
            cliffStream.token,
            cliffStream.startTime,
            cliffStream.stopTime,
            cliffStream.cliffTime,
            cancelable
        );

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__RenounceNonCancelableStream.selector, nonCancelableStreamId)
        );
        sablierV2Cliff.renounce(nonCancelableStreamId);
    }

    /// @dev When all checks pass, it should make the stream non-cancelable.
    function testRenounce() external {
        sablierV2Cliff.renounce(streamId);
        ISablierV2Cliff.CliffStream memory cliffStream = sablierV2Cliff.getCliffStream(streamId);
        assertEq(cliffStream.cancelable, false);
    }

    /// @dev When all checks pass, it should emit a Renounce event.
    function testRenounce__Event() external {
        vm.expectEmit(true, false, false, false);
        emit Renounce(streamId);
        sablierV2Cliff.renounce(streamId);
    }
}
