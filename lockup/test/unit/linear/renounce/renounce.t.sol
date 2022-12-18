// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract Renounce__Test is SablierV2LinearTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();
    }

    /// @dev it should revert.
    function testCannotRenounce__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Linear.renounce(nonStreamId);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should revert.
    function testCannotRenounce__CallerNotSender() external StreamExistent {
        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        sablierV2Linear.renounce(daiStreamId);
    }

    modifier CallerSender() {
        _;
    }

    /// @dev it should revert.
    function testCannotRenounce__NonCancelabeStream() external StreamExistent CallerSender {
        // Create the non-cancelable stream.
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__RenounceNonCancelableStream.selector, nonCancelableDaiStreamId)
        );
        sablierV2Linear.renounce(nonCancelableDaiStreamId);
    }

    /// @dev it should make the stream non-cancelable.
    function testRenounce() external StreamExistent CallerSender {
        sablierV2Linear.renounce(daiStreamId);
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.cancelable, false);
    }

    /// @dev it should emit a Renounce event.
    function testRenounce__Event() external {
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: false });
        emit Events.Renounce(daiStreamId);
        sablierV2Linear.renounce(daiStreamId);
    }
}
