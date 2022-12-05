// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2ProTest } from "../SablierV2ProTest.t.sol";

contract Renounce__Test is SablierV2ProTest {
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
        sablierV2Pro.renounce(nonStreamId);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should revert.
    function testCannotRenounce__CallerNotSender() external StreamExistent {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        sablierV2Pro.renounce(daiStreamId);
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
        sablierV2Pro.renounce(nonCancelableDaiStreamId);
    }

    /// @dev it should make the stream non-cancelable.
    function testRenounce() external StreamExistent CallerSender {
        sablierV2Pro.renounce(daiStreamId);
        DataTypes.ProStream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        assertEq(actualStream.cancelable, false);
    }

    /// @dev it should emit a Renounce event.
    function testRenounce__Event() external {
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: false });
        emit Events.Renounce(daiStreamId);
        sablierV2Pro.renounce(daiStreamId);
    }
}
