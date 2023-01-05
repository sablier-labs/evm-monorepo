// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SharedTest } from "../SharedTest.t.sol";

abstract contract CancelMultiple__Test is SharedTest {
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override {
        super.setUp();

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should do nothing.
    function testCannotCancelMultiple__OnlyNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(nonStreamId);
        sablierV2.cancelMultiple(streamIds);
    }

    /// @dev it should ignore the non-existent streams and cancel the existent streams.
    function testCannotCancelMultiple__SomeNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], nonStreamId);
        sablierV2.cancelMultiple(streamIds);
        assertDeleted(defaultStreamIds[0]);
    }

    modifier OnlyExistentStreams() {
        _;
    }

    /// @dev it should do nothing.
    function testCannotCancelMultiple__AllStreamsNonCancelable() external OnlyExistentStreams {
        // Create the non-cancelable stream.
        uint256 streamId = createDefaultStreamNonCancelable();

        // Run the test.
        uint256[] memory nonCancelableStreamIds = Solarray.uint256s(streamId);
        sablierV2.cancelMultiple(nonCancelableStreamIds);
    }

    /// @dev it should ignore the non-cancelable streams and cancel the cancelable streams.
    function testCannotCancelMultiple__SomeStreamsNonCancelable() external OnlyExistentStreams {
        // Create the non-cancelable stream.
        uint256 streamId = createDefaultStreamNonCancelable();

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], streamId);
        sablierV2.cancelMultiple(streamIds);

        // Assert that the cancelable stream was canceled.
        assertDeleted(defaultStreamIds[0]);

        // Assert that the non-cancelable stream was not canceled.
        bool isEntity = sablierV2.isEntity(defaultStreamIds[1]);
        assertTrue(isEntity);
    }

    modifier AllStreamsCancelable() {
        _;
    }

    /// @dev it should revert.
    function testCannotCancelMultiple__CallerUnauthorizedAllStreams__MaliciousThirdParty(
        address eve
    ) external OnlyExistentStreams AllStreamsCancelable {
        vm.assume(eve != address(0) && eve != users.sender && eve != users.recipient);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], eve));
        sablierV2.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function testCannotCancelMultiple__CallerUnauthorizedAllStreams__ApprovedOperator(
        address operator
    ) external OnlyExistentStreams AllStreamsCancelable {
        vm.assume(operator != address(0) && operator != users.sender && operator != users.recipient);

        // Approve the operator for all streams.
        sablierV2.setApprovalForAll({ operator: operator, _approved: true });

        // Make the approved operator the caller in this test.
        changePrank(users.operator);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.operator)
        );
        sablierV2.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function testCannotCancelMultiple__CallerUnauthorizedAllStreams__FormerRecipient()
        external
        OnlyExistentStreams
        AllStreamsCancelable
    {
        // Transfer the streams to Alice.
        sablierV2.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });
        sablierV2.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[1] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        sablierV2.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function testCannotCancelMultiple__CallerUnauthorizedSomeStreams__MaliciousThirdParty(
        address eve
    ) external OnlyExistentStreams AllStreamsCancelable {
        vm.assume(eve != address(0) && eve != users.sender && eve != users.recipient);

        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Create a stream with Eve as the sender.
        uint256 eveStreamId = createDefaultStreamWithSender(users.eve);

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2.cancelMultiple(streamIds);
    }

    /// @dev it should revert.
    function testCannotCancelMultiple__CallerUnauthorizedSomeStreams__ApprovedOperator(
        address operator
    ) external OnlyExistentStreams AllStreamsCancelable {
        vm.assume(operator != address(0) && operator != users.sender && operator != users.recipient);

        // Approve the operator to handle the first stream.
        sablierV2.approve({ to: users.operator, tokenId: defaultStreamIds[0] });

        // Make the approved operator the caller in this test.
        changePrank(users.operator);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.operator)
        );
        sablierV2.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function testCannotCancelMultiple__CallerUnauthorizedSomeStreams__FormerRecipient()
        external
        OnlyExistentStreams
        AllStreamsCancelable
    {
        // Transfer the first stream to Eve.
        sablierV2.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        sablierV2.cancelMultiple(defaultStreamIds);
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
    function testCancelMultiple__Sender(
        uint256 timeWarp,
        uint40 stopTime
    ) external OnlyExistentStreams AllStreamsCancelable CallerAuthorizedAllStreams {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION * 2);
        stopTime = boundUint40(
            stopTime,
            DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION / 2,
            DEFAULT_STOP_TIME + DEFAULT_TOTAL_DURATION / 2
        );

        // Make the sender the caller in this test.
        changePrank(users.sender);

        // Create a new stream with a different stop time.
        uint256 streamId = createDefaultStreamWithStopTime(stopTime);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Create the stream ids array.
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], streamId);

        // Expect the tokens to be withdrawn to the recipient, if not zero.
        uint128 withdrawAmount0 = sablierV2.getWithdrawableAmount(streamIds[0]);
        if (withdrawAmount0 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount0)));
        }
        uint128 withdrawAmount1 = sablierV2.getWithdrawableAmount(streamIds[1]);
        if (withdrawAmount1 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount1)));
        }

        // Expect the tokens to be returned to the sender, if not zero.
        uint128 returnAmount0 = DEFAULT_NET_DEPOSIT_AMOUNT - withdrawAmount0;
        if (returnAmount0 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.sender, returnAmount0)));
        }
        uint128 returnAmount1 = DEFAULT_NET_DEPOSIT_AMOUNT - withdrawAmount1;
        if (returnAmount1 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.sender, returnAmount1)));
        }

        // Expect Cancel events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamIds[0], users.sender, users.recipient, returnAmount0, withdrawAmount0);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamIds[1], users.sender, users.recipient, returnAmount1, withdrawAmount1);

        // Cancel the streams.
        sablierV2.cancelMultiple(streamIds);

        // Assert that the streams were deleted.
        assertDeleted(Solarray.uint256s(streamIds[0], streamIds[1]));

        // Assert that the NFTs weren't burned.
        address actualNFTOwner0 = sablierV2.ownerOf({ tokenId: streamIds[0] });
        address actualNFTOwner1 = sablierV2.ownerOf({ tokenId: streamIds[1] });
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
    function testCancelMultiple__Recipient(
        uint256 timeWarp,
        uint40 stopTime
    ) external OnlyExistentStreams AllStreamsCancelable CallerAuthorizedAllStreams {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION * 2);
        stopTime = boundUint40(
            stopTime,
            DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION / 2,
            DEFAULT_STOP_TIME + DEFAULT_TOTAL_DURATION / 2
        );

        // Make the recipient the caller in this test.
        changePrank(users.recipient);

        // Create a new stream with a different stop time.
        uint256 streamId = createDefaultStreamWithStopTime(stopTime);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Create the stream ids array.
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], streamId);

        // Expect the tokens to be withdrawn to the recipient, if not zero.
        uint128 withdrawAmount0 = sablierV2.getWithdrawableAmount(streamIds[0]);
        if (withdrawAmount0 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount0)));
        }
        uint128 withdrawAmount1 = sablierV2.getWithdrawableAmount(streamIds[1]);
        if (withdrawAmount1 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount1)));
        }

        // Expect the tokens to be returned to the sender, if not zero.
        uint128 returnAmount0 = DEFAULT_NET_DEPOSIT_AMOUNT - withdrawAmount0;
        if (returnAmount0 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.sender, returnAmount0)));
        }
        uint128 returnAmount1 = DEFAULT_NET_DEPOSIT_AMOUNT - withdrawAmount1;
        if (returnAmount1 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.sender, returnAmount1)));
        }

        // Expect Cancel events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamIds[0], users.sender, users.recipient, returnAmount0, withdrawAmount0);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamIds[1], users.sender, users.recipient, returnAmount1, withdrawAmount1);

        // Cancel the streams.
        sablierV2.cancelMultiple(streamIds);

        // Assert that the streams were deleted.
        assertDeleted(Solarray.uint256s(streamIds[0], streamIds[1]));

        // Assert that the NFTs weren't burned.
        address actualNFTOwner0 = sablierV2.getRecipient(streamIds[0]);
        address actualNFTOwner1 = sablierV2.getRecipient(streamIds[1]);
        address expectedRecipient = users.recipient;
        assertEq(actualNFTOwner0, expectedRecipient);
        assertEq(actualNFTOwner1, expectedRecipient);
    }
}
