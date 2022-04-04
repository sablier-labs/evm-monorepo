// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2UnitTest } from "../../SablierV2UnitTest.t.sol";

contract SablierV2Linear__LetGo__UnitTest is SablierV2UnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultLinearStream();
    }

    /// @dev When the linear stream does not exist, it should revert.
    function testCannotLetGo__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Linear.letGo(nonStreamId);
    }

    /// @dev When the linear stream does not exist, it should revert.
    function testCannotLetGo__Unauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        sablierV2Linear.letGo(streamId);
    }

    /// @dev When the linear stream is already non-cancelable, it should revert.
    function testCannotLetGo__NonCancelabeStream() external {
        // Creaate the non-cancelable stream.
        bool cancelable = false;
        uint256 nonCancelableStreamId = sablierV2Linear.create(
            linearStream.sender,
            linearStream.recipient,
            linearStream.depositAmount,
            linearStream.token,
            linearStream.startTime,
            linearStream.stopTime,
            cancelable
        );

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__LetGoNonCancelableStream.selector, nonCancelableStreamId)
        );
        sablierV2Linear.letGo(nonCancelableStreamId);
    }

    /// @dev When all checks pass, it should make the stream non-cancelable.
    function testLetGo() external {
        sablierV2Linear.letGo(streamId);
        ISablierV2Linear.LinearStream memory linearStream = sablierV2Linear.getLinearStream(streamId);
        assertEq(linearStream.cancelable, false);
    }

    /// @dev When all checks pass, it should emit a LetGo event.
    function testLetGo__Event() external {
        vm.expectEmit(true, false, false, false);
        emit LetGo(streamId);
        sablierV2Linear.letGo(streamId);
    }
}
