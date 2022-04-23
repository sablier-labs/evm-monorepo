// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__LetGo__UnitTest is SablierV2CliffUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultCliffStream();
    }

    /// @dev When the cliff stream does not exist, it should revert.
    function testCannotLetGo__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Cliff.letGo(nonStreamId);
    }

    /// @dev When the cliff stream does not exist, it should revert.
    function testCannotLetGo__Unauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        sablierV2Cliff.letGo(streamId);
    }

    /// @dev When the cliff stream is already non-cancelable, it should revert.
    function testCannotLetGo__NonCancelabeStream() external {
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
            abi.encodeWithSelector(ISablierV2.SablierV2__LetGoNonCancelableStream.selector, nonCancelableStreamId)
        );
        sablierV2Cliff.letGo(nonCancelableStreamId);
    }

    /// @dev When all checks pass, it should make the stream non-cancelable.
    function testLetGo() external {
        sablierV2Cliff.letGo(streamId);
        ISablierV2Cliff.CliffStream memory cliffStream = sablierV2Cliff.getCliffStream(streamId);
        assertEq(cliffStream.cancelable, false);
    }

    /// @dev When all checks pass, it should emit a LetGo event.
    function testLetGo__Event() external {
        vm.expectEmit(true, false, false, false);
        emit LetGo(streamId);
        sablierV2Cliff.letGo(streamId);
    }
}
