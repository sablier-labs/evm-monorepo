// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__Renounce is SablierV2CliffUnitTest {
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
        sablierV2Cliff.renounce(nonStreamId);
    }

    /// @dev When the caller is neither the sender nor the recipient, it should revert.
    function testCannotRenounce__CallerUnauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        sablierV2Cliff.renounce(streamId);
    }

    /// @dev When the stream is already non-cancelable, it should revert.
    function testCannotRenounce__NonCancelabeStream() external {
        // Creaate the non-cancelable stream.
        bool cancelable = false;
        uint256 nonCancelableStreamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            stream.stopTime,
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
        ISablierV2Cliff.Stream memory queriedStream = sablierV2Cliff.getStream(streamId);
        assertEq(queriedStream.cancelable, false);
    }

    /// @dev When all checks pass, it should emit a Renounce event.
    function testRenounce__Event() external {
        vm.expectEmit(true, false, false, false);
        emit Renounce(streamId);
        sablierV2Cliff.renounce(streamId);
    }
}
