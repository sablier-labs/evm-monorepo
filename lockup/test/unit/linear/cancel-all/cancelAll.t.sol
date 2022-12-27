// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract CancelAll__Test is LinearTest {
    uint256[] internal defaultStreamIds;

    function setUp() public override {
        super.setUp();

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should do nothing.
    function testCannotCancelAll__OnlyNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(nonStreamId);
        linear.cancelAll(streamIds);
    }

    /// @dev it should ignore the non-existent streams and cancel the existent streams.
    function testCannotCancelAll__SomeNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], nonStreamId);
        linear.cancelAll(streamIds);
        DataTypes.LinearStream memory actualStream = linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier OnlyExistentStreams() {
        _;
    }

    /// @dev it should do nothing.
    function testCannotCancelAll__AllStreamsNonCancelable() external OnlyExistentStreams {
        // Create the non-cancelable stream.
        uint256 streamId = createDefaultStreamNonCancelable();

        // Run the test.
        uint256[] memory nonCancelableStreamIds = createDynamicArray(streamId);
        linear.cancelAll(nonCancelableStreamIds);
    }

    /// @dev it should ignore the non-cancelable streams and cancel the cancelable streams.
    function testCannotCancelAll__SomeStreamsNonCancelable() external OnlyExistentStreams {
        // Create the non-cancelable stream.
        uint256 streamId = createDefaultStreamNonCancelable();

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], streamId);
        linear.cancelAll(streamIds);
        DataTypes.LinearStream memory actualStream0 = linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory actualStream1 = linear.getStream(streamId);
        DataTypes.LinearStream memory expectedStream0;
        DataTypes.LinearStream memory expectedStream1 = defaultStream;
        expectedStream1.isCancelable = false;
        assertEq(actualStream0, expectedStream0);
        assertEq(actualStream1, expectedStream1);
    }

    modifier AllStreamsCancelable() {
        _;
    }

    /// @dev it should revert.
    function testCannotCancelAll__CallerUnauthorizedAllStreams__MaliciousThirdParty(
        address eve
    ) external OnlyExistentStreams AllStreamsCancelable {
        vm.assume(eve != address(0) && eve != defaultStream.sender && eve != users.recipient);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], eve));
        linear.cancelAll(defaultStreamIds);
    }

    /// @dev it should revert.
    function testCannotCancelAll__CallerUnauthorizedAllStreams__ApprovedOperator(
        address operator
    ) external OnlyExistentStreams AllStreamsCancelable {
        vm.assume(operator != address(0) && operator != defaultStream.sender && operator != users.recipient);

        // Approve the operator for all streams.
        linear.setApprovalForAll({ operator: operator, approved: true });

        // Make the approved operator the caller in this test.
        changePrank(users.operator);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.operator)
        );
        linear.cancelAll(defaultStreamIds);
    }

    /// @dev it should revert.
    function testCannotCancelAll__CallerUnauthorizedAllStreams__FormerRecipient()
        external
        OnlyExistentStreams
        AllStreamsCancelable
    {
        // Transfer the streams to Alice.
        linear.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });
        linear.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[1] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        linear.cancelAll(defaultStreamIds);
    }

    /// @dev it should revert.
    function testCannotCancelAll__CallerUnauthorizedSomeStreams__MaliciousThirdParty(
        address eve
    ) external OnlyExistentStreams AllStreamsCancelable {
        vm.assume(eve != address(0) && eve != defaultStream.sender && eve != users.recipient);

        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Create a stream with Eve as the sender.
        uint256 eveStreamId = createDefaultStreamWithSender(users.eve);

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        linear.cancelAll(streamIds);
    }

    /// @dev it should revert.
    function testCannotCancelAll__CallerUnauthorizedSomeStreams__ApprovedOperator(
        address operator
    ) external OnlyExistentStreams AllStreamsCancelable {
        vm.assume(operator != address(0) && operator != defaultStream.sender && operator != users.recipient);

        // Approve the operator to handle the first stream.
        linear.approve({ to: users.operator, tokenId: defaultStreamIds[0] });

        // Make the approved operator the caller in this test.
        changePrank(users.operator);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.operator)
        );
        linear.cancelAll(defaultStreamIds);
    }

    /// @dev it should revert.
    function testCannotCancelAll__CallerUnauthorizedSomeStreams__FormerRecipient()
        external
        OnlyExistentStreams
        AllStreamsCancelable
    {
        // Transfer the first stream to Eve.
        linear.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        linear.cancelAll(defaultStreamIds);
    }

    modifier CallerAuthorizedAllStreams() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, emit Cancel events, and cancel the streams.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All streams ended.
    /// - All streams ongoing.
    /// - Some streams ended, some streams ongoing.
    function testCancelAll__Sender(
        uint256 timeWarp,
        uint40 stopTime
    ) external OnlyExistentStreams AllStreamsCancelable CallerAuthorizedAllStreams {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION * 2);
        stopTime = boundUint40(
            stopTime,
            defaultStream.startTime + DEFAULT_TOTAL_DURATION / 2,
            defaultStream.stopTime + DEFAULT_TOTAL_DURATION / 2
        );

        // Make the the sender the caller in this test.
        changePrank(users.sender);

        // Create a new stream with a different stop time.
        uint256 streamId = createDefaultStreamWithStopTime(stopTime);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.startTime + timeWarp });

        // Create the stream ids array.
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], streamId);

        // Expect the tokens to be withdrawn to the recipient, if not zero.
        uint128 withdrawAmount0 = linear.getWithdrawableAmount(streamIds[0]);
        if (withdrawAmount0 > 0) {
            vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount0)));
        }
        uint128 withdrawAmount1 = linear.getWithdrawableAmount(streamIds[1]);
        if (withdrawAmount1 > 0) {
            vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount1)));
        }

        // Expect the tokens to be returned to the sender, if not zero.
        uint128 returnAmount0 = defaultStream.depositAmount - withdrawAmount0;
        if (returnAmount0 > 0) {
            vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (defaultStream.sender, returnAmount0)));
        }
        uint128 returnAmount1 = defaultStream.depositAmount - withdrawAmount1;
        if (returnAmount1 > 0) {
            vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (defaultStream.sender, returnAmount1)));
        }

        // Expect Cancel events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamIds[0], defaultStream.sender, users.recipient, returnAmount0, withdrawAmount0);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamIds[1], defaultStream.sender, users.recipient, returnAmount1, withdrawAmount1);

        // Cancel the streams.
        linear.cancelAll(streamIds);

        // Assert that the streams were deleted.
        DataTypes.LinearStream memory actualStream0 = linear.getStream(streamIds[0]);
        DataTypes.LinearStream memory actualStream1 = linear.getStream(streamIds[1]);
        DataTypes.LinearStream memory expectedStream;
        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);

        // Assert that the NFTs weren't burned.
        address actualNFTOwner0 = linear.ownerOf({ tokenId: streamIds[0] });
        address actualNFTOwner1 = linear.ownerOf({ tokenId: streamIds[1] });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner0, expectedNFTOwner);
        assertEq(actualNFTOwner1, expectedNFTOwner);
    }

    /// @dev it should perform the ERC-20 transfers, emit Cancel events, and cancel the streams.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All streams ended.
    /// - All streams ongoing.
    /// - Some streams ended, some streams ongoing.
    function testCancelAll__Recipient(
        uint256 timeWarp,
        uint40 stopTime
    ) external OnlyExistentStreams AllStreamsCancelable CallerAuthorizedAllStreams {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION * 2);
        stopTime = boundUint40(
            stopTime,
            defaultStream.startTime + DEFAULT_TOTAL_DURATION / 2,
            defaultStream.stopTime + DEFAULT_TOTAL_DURATION / 2
        );

        // Make the the recipient the caller in this test.
        changePrank(users.recipient);

        // Create a new stream with a different stop time.
        uint256 streamId = createDefaultStreamWithStopTime(stopTime);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.startTime + timeWarp });

        // Create the stream ids array.
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], streamId);

        // Expect the tokens to be withdrawn to the recipient, if not zero.
        uint128 withdrawAmount0 = linear.getWithdrawableAmount(streamIds[0]);
        if (withdrawAmount0 > 0) {
            vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount0)));
        }
        uint128 withdrawAmount1 = linear.getWithdrawableAmount(streamIds[1]);
        if (withdrawAmount1 > 0) {
            vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount1)));
        }

        // Expect the tokens to be returned to the sender, if not zero.
        uint128 returnAmount0 = defaultStream.depositAmount - withdrawAmount0;
        if (returnAmount0 > 0) {
            vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (defaultStream.sender, returnAmount0)));
        }
        uint128 returnAmount1 = defaultStream.depositAmount - withdrawAmount1;
        if (returnAmount1 > 0) {
            vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (defaultStream.sender, returnAmount1)));
        }

        // Expect Cancel events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamIds[0], defaultStream.sender, users.recipient, returnAmount0, withdrawAmount0);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamIds[1], defaultStream.sender, users.recipient, returnAmount1, withdrawAmount1);

        // Cancel the streams.
        linear.cancelAll(streamIds);

        // Assert that the streams were deleted.
        DataTypes.LinearStream memory actualStream0 = linear.getStream(streamIds[0]);
        DataTypes.LinearStream memory actualStream1 = linear.getStream(streamIds[1]);
        DataTypes.LinearStream memory expectedStream;
        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);

        // Assert that the NFTs weren't burned.
        address actualNFTOwner0 = linear.getRecipient(streamIds[0]);
        address actualNFTOwner1 = linear.getRecipient(streamIds[1]);
        address expectedRecipient = users.recipient;
        assertEq(actualNFTOwner0, expectedRecipient);
        assertEq(actualNFTOwner1, expectedRecipient);
    }
}
