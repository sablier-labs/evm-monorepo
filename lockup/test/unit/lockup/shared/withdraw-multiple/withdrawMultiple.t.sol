// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Status } from "src/types/Enums.sol";

import { Shared_Test } from "../SharedTest.t.sol";

abstract contract WithdrawMultiple_Test is Shared_Test {
    uint128[] internal defaultAmounts;
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override {
        super.setUp();

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
    function test_RevertWhen_ToZeroAddress() external {
        vm.expectRevert(Errors.SablierV2Lockup_WithdrawToZeroAddress.selector);
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: address(0), amounts: defaultAmounts });
    }

    modifier toNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ArraysNotEqual() external toNonZeroAddress {
        uint256[] memory streamIds = new uint256[](2);
        uint128[] memory amounts = new uint128[](1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_WithdrawArraysNotEqual.selector,
                streamIds.length,
                amounts.length
            )
        );
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: amounts });
    }

    modifier arraysEqual() {
        _;
    }

    /// @dev it should do nothing.
    function test_RevertWhen_OnlyNullStreams() external toNonZeroAddress arraysEqual {
        uint256 nullStreamId = 1729;
        uint256[] memory nonStreamIds = Solarray.uint256s(nullStreamId);
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT);
        lockup.withdrawMultiple({ streamIds: nonStreamIds, to: users.recipient, amounts: amounts });
    }

    /// @dev it should ignore the null streams and make the withdrawals for the non-null ones.
    function test_RevertWhen_SomeNullStreams() external toNonZeroAddress arraysEqual {
        uint256 nullStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(nullStreamId, defaultStreamIds[0]);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier onlyNonNullStreams() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty(
        address eve
    ) external toNonZeroAddress arraysEqual onlyNonNullStreams {
        vm.assume(eve != address(0) && eve != users.sender && eve != users.recipient);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], eve));
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_Sender()
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
    {
        // Make the sender the caller in this test.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.sender)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.sender, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_FormerRecipient()
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
    {
        // Transfer all streams to Alice.
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[1] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CallerUnauthorizedSomeStreams_MaliciousThirdParty(
        address eve
    ) external toNonZeroAddress arraysEqual onlyNonNullStreams {
        vm.assume(eve != address(0) && eve != users.sender && eve != users.recipient);

        // Create a stream with Eve as the recipient.
        uint256 eveStreamId = createDefaultStreamWithRecipient(eve);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], eve));
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedSomeStreams_FormerRecipient()
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
    {
        // Transfer one of the streams to Eve.
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    modifier callerAuthorizedAllStreams() {
        _;
    }

    /// @dev it should make the withdrawals and update the withdrawn amounts.
    function testFuzz_WithdrawMultiple_CallerApprovedOperator(
        address to
    ) external toNonZeroAddress arraysEqual onlyNonNullStreams callerAuthorizedAllStreams {
        vm.assume(to != address(0));

        // Approve the operator for all streams.
        lockup.setApprovalForAll(users.operator, true);

        // Make the operator the caller in this test.
        changePrank(users.operator);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Expect the withdrawals to be made.
        uint128 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT;
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));

        // Make the withdrawals.
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: defaultAmounts });

        // Assert that the withdrawn amounts were updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount);
    }

    modifier callerRecipient() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_SomeAmountsZero()
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
        callerAuthorizedAllStreams
        callerRecipient
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT, 0);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_WithdrawAmountZero.selector, defaultStreamIds[1])
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: amounts });
    }

    modifier allAmountsNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_SomeAmountsGreaterThanWithdrawableAmount()
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
        callerAuthorizedAllStreams
        callerRecipient
        allAmountsNotZero
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint128 withdrawableAmount = lockup.getWithdrawableAmount(defaultStreamIds[1]);
        uint128[] memory amounts = Solarray.uint128s(withdrawableAmount, UINT128_MAX);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_WithdrawAmountGreaterThanWithdrawableAmount.selector,
                defaultStreamIds[1],
                UINT128_MAX,
                withdrawableAmount
            )
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: amounts });
    }

    modifier allAmountsLessThanOrEqualToWithdrawableAmounts() {
        _;
    }

    /// @dev it should make the withdrawals, emit multiple WithdrawFromLockupStream events, and mark the streams as
    /// depleted.
    function testFuzz_WithdrawMultiple_AllStreamsEnded(
        uint256 timeWarp,
        address to
    )
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
        callerAuthorizedAllStreams
        callerRecipient
        allAmountsNotZero
        allAmountsLessThanOrEqualToWithdrawableAmounts
    {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);
        vm.assume(to != address(0));

        // Warp into the future, past the stop time.
        vm.warp({ timestamp: DEFAULT_STOP_TIME + timeWarp });

        // Expect WithdrawFromLockupStream events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.WithdrawFromLockupStream({
            streamId: defaultStreamIds[0],
            to: to,
            amount: DEFAULT_NET_DEPOSIT_AMOUNT
        });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.WithdrawFromLockupStream({
            streamId: defaultStreamIds[1],
            to: to,
            amount: DEFAULT_NET_DEPOSIT_AMOUNT
        });

        // Expect the withdrawals to be made.
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (to, DEFAULT_NET_DEPOSIT_AMOUNT)));
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (to, DEFAULT_NET_DEPOSIT_AMOUNT)));

        // Make the withdrawals.
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_NET_DEPOSIT_AMOUNT, DEFAULT_NET_DEPOSIT_AMOUNT);
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: amounts });

        // Assert that the streams were marked as depleted.
        Status actualStatus0 = lockup.getStatus(defaultStreamIds[0]);
        Status actualStatus1 = lockup.getStatus(defaultStreamIds[1]);
        Status expectedStatus = Status.DEPLETED;
        assertEq(actualStatus0, expectedStatus);
        assertEq(actualStatus1, expectedStatus);

        // Assert that the NFTs weren't burned.
        address actualNFTOwner0 = lockup.ownerOf(defaultStreamIds[0]);
        address actualNFTOwner1 = lockup.ownerOf(defaultStreamIds[1]);
        address actualNFTOwner = users.recipient;
        assertEq(actualNFTOwner0, actualNFTOwner);
        assertEq(actualNFTOwner1, actualNFTOwner);
    }

    /// @dev it should make the withdrawals, emit multiple WithdrawFromLockupStream events, and update the withdrawn
    /// amounts.
    function testFuzz_WithdrawMultiple_AllStreamsOngoing(
        uint256 timeWarp,
        address to,
        uint128 withdrawAmount
    )
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
        callerAuthorizedAllStreams
        callerRecipient
        allAmountsNotZero
        allAmountsLessThanOrEqualToWithdrawableAmounts
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        vm.assume(to != address(0));

        // Warp into the future, before the stop time of the stream.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the withdraw amount.
        uint128 withdrawableAmount = lockup.getWithdrawableAmount(defaultStreamIds[0]);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Expect the withdrawals to be made.
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));

        // Expect WithdrawFromLockupStream events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.WithdrawFromLockupStream({ streamId: defaultStreamIds[0], to: to, amount: withdrawAmount });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.WithdrawFromLockupStream({ streamId: defaultStreamIds[1], to: to, amount: withdrawAmount });

        // Make the withdrawals.
        uint128[] memory amounts = Solarray.uint128s(withdrawAmount, withdrawAmount);
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: amounts });

        // Assert that the withdrawn amounts were updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount);
    }

    /// @dev it should make the withdrawals, emit multiple WithdrawFromLockupStream events, mark the ended streams as
    /// depleted, and update the withdrawn amounts.
    function testFuzz_WithdrawMultiple_SomeStreamsEndedSomeStreamsOngoing(
        uint256 timeWarp,
        address to,
        uint128 ongoingWithdrawAmount
    )
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
        callerAuthorizedAllStreams
        callerRecipient
        allAmountsNotZero
        allAmountsLessThanOrEqualToWithdrawableAmounts
    {
        timeWarp = bound(timeWarp, DEFAULT_TOTAL_DURATION, DEFAULT_TOTAL_DURATION * 2 - 1);
        vm.assume(to != address(0));

        // Use the first default stream as the ended stream.
        uint256 endedStreamId = defaultStreamIds[0];
        uint128 endedWithdrawAmount = DEFAULT_NET_DEPOSIT_AMOUNT;

        // Create a new stream with a stop time nearly double that of the default stream.
        uint40 ongoingStopTime = DEFAULT_STOP_TIME + DEFAULT_TOTAL_DURATION;
        uint256 ongoingStreamId = createDefaultStreamWithStopTime(ongoingStopTime);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the ongoing withdraw amount.
        uint128 ongoingWithdrawableAmount = lockup.getWithdrawableAmount(ongoingStreamId);
        ongoingWithdrawAmount = boundUint128(ongoingWithdrawAmount, 1, ongoingWithdrawableAmount);

        // Expect WithdrawFromLockupStream events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.WithdrawFromLockupStream({ streamId: endedStreamId, to: to, amount: endedWithdrawAmount });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.WithdrawFromLockupStream({ streamId: ongoingStreamId, to: to, amount: ongoingWithdrawAmount });

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(endedStreamId, ongoingStreamId);
        uint128[] memory amounts = Solarray.uint128s(endedWithdrawAmount, ongoingWithdrawAmount);
        lockup.withdrawMultiple({ streamIds: streamIds, to: to, amounts: amounts });

        // Assert that the ended stream was marked as depleted.
        Status actualStatus = lockup.getStatus(endedStreamId);
        Status expectedStatus = Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the ended stream NFT was not burned.
        address actualEndedNFTOwner = lockup.getRecipient(endedStreamId);
        address expectedEndedNFTOwner = users.recipient;
        assertEq(actualEndedNFTOwner, expectedEndedNFTOwner);

        // Assert that the withdrawn amount was updated for the ongoing stream.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(ongoingStreamId);
        uint128 expectedWithdrawnAmount = ongoingWithdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }
}
