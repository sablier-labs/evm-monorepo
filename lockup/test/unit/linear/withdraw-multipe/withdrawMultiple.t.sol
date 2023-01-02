// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { LinearStream } from "src/types/Structs.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract WithdrawMultiple__LinearTest is LinearTest {
    uint128[] internal defaultAmounts;
    uint256[] internal defaultStreamIds;

    function setUp() public override {
        LinearTest.setUp();

        // Define the default amounts, since most tests need them.
        defaultAmounts.push(DEFAULT_WITHDRAW_AMOUNT);
        defaultAmounts.push(DEFAULT_WITHDRAW_AMOUNT);

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__ToZeroAddress() external {
        vm.expectRevert(Errors.SablierV2__WithdrawToZeroAddress.selector);
        linear.withdrawMultiple({ streamIds: defaultStreamIds, to: address(0), amounts: defaultAmounts });
    }

    modifier ToNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__ArraysNotEqual() external ToNonZeroAddress {
        uint256[] memory streamIds = new uint256[](2);
        uint128[] memory amounts = new uint128[](1);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__WithdrawArraysNotEqual.selector, streamIds.length, amounts.length)
        );
        linear.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: amounts });
    }

    modifier ArraysEqual() {
        _;
    }

    /// @dev it should do nothing.
    function testCannotWithdrawMultiple__OnlyNonExistentStreams() external ToNonZeroAddress ArraysEqual {
        uint256 nonStreamId = 1729;
        uint256[] memory nonStreamIds = Solarray.uint256s(nonStreamId);
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT);
        linear.withdrawMultiple({ streamIds: nonStreamIds, to: users.recipient, amounts: amounts });
    }

    /// @dev it should ignore the non-existent streams and make the withdrawals for the existent streams.
    function testCannotWithdrawMultiple__SomeNonExistentStreams() external ToNonZeroAddress ArraysEqual {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(nonStreamId, defaultStreamIds[0]);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: defaultStream.range.start + DEFAULT_TIME_WARP });

        // Run the test.
        linear.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
        uint128 actualWithdrawnAmount = linear.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier OnlyExistentStreams() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__CallerUnauthorizedAllStreams__MaliciousThirdParty(
        address eve
    ) external ToNonZeroAddress ArraysEqual OnlyExistentStreams {
        vm.assume(eve != address(0) && eve != defaultStream.sender && eve != users.recipient);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], eve));
        linear.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__CallerUnauthorizedAllStreams__Sender()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
    {
        // Make the sender the caller in this test.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], defaultStream.sender)
        );
        linear.withdrawMultiple({ streamIds: defaultStreamIds, to: defaultStream.sender, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__CallerUnauthorizedAllStreams__FormerRecipient()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
    {
        // Transfer all streams to Alice.
        linear.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });
        linear.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[1] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        linear.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__CallerUnauthorizedSomeStreams__MaliciousThirdParty(
        address eve
    ) external ToNonZeroAddress ArraysEqual OnlyExistentStreams {
        vm.assume(eve != address(0) && eve != defaultStream.sender && eve != users.recipient);

        // Create a stream with Eve as the recipient.
        uint256 eveStreamId = createDefaultStreamWithRecipient(eve);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: defaultStream.range.start + DEFAULT_TIME_WARP });

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], eve));
        linear.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__CallerUnauthorizedSomeStreams__FormerRecipient()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
    {
        // Transfer one of the streams to Eve.
        linear.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: defaultStream.range.start + DEFAULT_TIME_WARP });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        linear.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    modifier CallerAuthorizedAllStreams() {
        _;
    }

    /// @dev it should make the withdrawals and update the withdrawn amounts.
    function testWithdrawMultiple__CallerApprovedOperator(
        address to
    ) external ToNonZeroAddress ArraysEqual OnlyExistentStreams CallerAuthorizedAllStreams {
        vm.assume(to != address(0));

        // Approve the operator for all streams.
        linear.setApprovalForAll(users.operator, true);

        // Make the operator the caller in this test.
        changePrank(users.operator);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: defaultStream.range.start + DEFAULT_TIME_WARP });

        // Expect the withdrawals to be made.
        uint128 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT;
        vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));
        vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));

        // Make the withdrawals.
        linear.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: defaultAmounts });

        // Assert that the withdrawn amounts were updated.
        uint128 actualWithdrawnAmount0 = linear.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = linear.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount);
    }

    modifier CallerRecipient() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__SomeAmountsZero()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipient
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: defaultStream.range.start + DEFAULT_TIME_WARP });

        // Run the test.
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT, 0);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__WithdrawAmountZero.selector, defaultStreamIds[1]));
        linear.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: amounts });
    }

    modifier AllAmountsNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__SomeAmountsGreaterThanWithdrawableAmount()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipient
        AllAmountsNotZero
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: defaultStream.range.start + DEFAULT_TIME_WARP });

        // Run the test.
        uint128 withdrawableAmount = DEFAULT_WITHDRAW_AMOUNT;
        uint128[] memory amounts = Solarray.uint128s(withdrawableAmount, UINT128_MAX);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                defaultStreamIds[1],
                UINT128_MAX,
                withdrawableAmount
            )
        );
        linear.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: amounts });
    }

    modifier AllAmountsLessThanOrEqualToWithdrawableAmounts() {
        _;
    }

    /// @dev it should make the withdrawals, emit multiple Withdraw events, and delete the streams.
    function testWithdrawMultiple__AllStreamsEnded(
        uint256 timeWarp,
        address to
    )
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipient
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);
        vm.assume(to != address(0));

        // Warp into the future, past the stop time.
        vm.warp({ timestamp: defaultStream.range.stop + timeWarp });

        // Expect Withdraw events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[0], to: to, amount: defaultStream.amounts.deposit });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[1], to: to, amount: defaultStream.amounts.deposit });

        // Expect the withdrawals to be made.
        vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (to, defaultStream.amounts.deposit)));
        vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (to, defaultStream.amounts.deposit)));

        // Make the withdrawals.
        uint128[] memory amounts = Solarray.uint128s(defaultStream.amounts.deposit, defaultStream.amounts.deposit);
        linear.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: amounts });

        // Assert that the streams were deleted.
        LinearStream memory actualStream0 = linear.getStream(defaultStreamIds[0]);
        LinearStream memory actualStream1 = linear.getStream(defaultStreamIds[1]);
        LinearStream memory expectedStream;
        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);

        // Assert that the NFTs weren't burned.
        address actualNFTOwner0 = linear.ownerOf(defaultStreamIds[0]);
        address actualNFTOwner1 = linear.ownerOf(defaultStreamIds[1]);
        address actualNFTOwner = users.recipient;
        assertEq(actualNFTOwner0, actualNFTOwner);
        assertEq(actualNFTOwner1, actualNFTOwner);
    }

    /// @dev it should make the withdrawals, emit multiple Withdraw events, and update the withdrawn amounts.
    function testWithdrawMultiple__AllStreamsOngoing(
        uint256 timeWarp,
        address to,
        uint128 withdrawAmount
    )
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipient
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        vm.assume(to != address(0));

        // Warp into the future, before the stop time of the stream.
        vm.warp({ timestamp: defaultStream.range.start + timeWarp });

        // Bound the withdraw amount.
        uint128 withdrawableAmount = linear.getWithdrawableAmount(defaultStreamIds[0]);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Expect the withdrawals to be made.
        vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));
        vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));

        // Expect Withdraw events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[0], to: to, amount: withdrawAmount });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[1], to: to, amount: withdrawAmount });

        // Make the withdrawals.
        uint128[] memory amounts = Solarray.uint128s(withdrawAmount, withdrawAmount);
        linear.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: amounts });

        // Assert that the withdrawn amounts were updated.
        uint128 actualWithdrawnAmount0 = linear.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = linear.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount);
    }

    /// @dev it should make the withdrawals, emit multiple Withdraw events, delete the ended streams, and update
    /// the withdrawn amounts.
    function testWithdrawMultiple__SomeStreamsEndedSomeStreamsOngoing(
        uint256 timeWarp,
        address to,
        uint128 ongoingWithdrawAmount
    )
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipient
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        timeWarp = bound(timeWarp, DEFAULT_TOTAL_DURATION, DEFAULT_TOTAL_DURATION * 2 - 1);
        vm.assume(to != address(0));

        // Use the first default stream as the ended stream.
        uint256 endedStreamId = defaultStreamIds[0];
        uint128 endedWithdrawAmount = defaultStream.amounts.deposit;

        // Create a new stream with a stop time nearly double that of the default stream.
        uint40 ongoingStopTime = defaultStream.range.stop + DEFAULT_TOTAL_DURATION;
        uint256 ongoingStreamId = createDefaultStreamWithStopTime(ongoingStopTime);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.range.start + timeWarp });

        // Bound the ongoing withdraw amount.
        uint128 ongoingWithdrawableAmount = linear.getWithdrawableAmount(ongoingStreamId);
        ongoingWithdrawAmount = boundUint128(ongoingWithdrawAmount, 1, ongoingWithdrawableAmount);

        // Expect Withdraw events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: endedStreamId, to: to, amount: endedWithdrawAmount });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: ongoingStreamId, to: to, amount: ongoingWithdrawAmount });

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(endedStreamId, ongoingStreamId);
        uint128[] memory amounts = Solarray.uint128s(endedWithdrawAmount, ongoingWithdrawAmount);
        linear.withdrawMultiple({ streamIds: streamIds, to: to, amounts: amounts });

        // Assert that the ended stream was deleted.
        LinearStream memory actualEndedStream = linear.getStream(endedStreamId);
        LinearStream memory expectedEndedStream;
        assertEq(actualEndedStream, expectedEndedStream);

        // Assert that the ended stream NFT was not burned.
        address actualEndedNFTOwner = linear.getRecipient(endedStreamId);
        address expectedEndedNFTOwner = users.recipient;
        assertEq(actualEndedNFTOwner, expectedEndedNFTOwner);

        // Assert that the withdrawn amount was updated for the ongoing stream.
        uint128 actualWithdrawnAmount = linear.getWithdrawnAmount(ongoingStreamId);
        uint128 expectedWithdrawnAmount = ongoingWithdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }
}
