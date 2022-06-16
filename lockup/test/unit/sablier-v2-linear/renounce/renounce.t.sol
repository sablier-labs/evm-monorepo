// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__Renounce is SablierV2LinearUnitTest {
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
        sablierV2Linear.renounce(nonStreamId);
    }

    /// @dev When the caller is not authorized, it should revert.
    function testCannotRenounce__CallerUnauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        sablierV2Linear.renounce(streamId);
    }

    /// @dev When the stream is already non-cancelable, it should revert.
    function testCannotRenounce__NonCancelabeStream() external {
        // Creaate the non-cancelable stream.
        bool cancelable = false;
        uint256 nonCancelableStreamId = sablierV2Linear.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.stopTime,
            cancelable
        );

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__RenounceNonCancelableStream.selector, nonCancelableStreamId)
        );
        sablierV2Linear.renounce(nonCancelableStreamId);
    }

    /// @dev When all checks pass, it should make the stream non-cancelable.
    function testRenounce() external {
        sablierV2Linear.renounce(streamId);
        ISablierV2Linear.Stream memory queriedStream = sablierV2Linear.getStream(streamId);
        assertEq(queriedStream.cancelable, false);
    }

    /// @dev When all checks pass, it should emit a Renounce event.
    function testRenounce__Event() external {
        vm.expectEmit(true, false, false, false);
        emit Renounce(streamId);
        sablierV2Linear.renounce(streamId);
    }
}
