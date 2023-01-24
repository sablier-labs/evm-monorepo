// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Status } from "src/types/Enums.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract WithdrawMultiple_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint128[] internal defaultAmounts;
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Define the default amounts, since most tests need them.
        defaultAmounts.push(DEFAULT_WITHDRAW_AMOUNT);
        defaultAmounts.push(DEFAULT_WITHDRAW_AMOUNT);

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the caller in this test suite.
        changePrank({ who: users.recipient });
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
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier onlyNonNullStreams() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty()
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
    {
        // Make Eve the caller in this test.
        changePrank({ who: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
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
        changePrank({ who: users.sender });

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
    function test_RevertWhen_CallerUnauthorizedSomeStreams_MaliciousThirdParty()
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
    {
        // Create a stream with Eve as the recipient.
        uint256 eveStreamId = createDefaultStreamWithRecipient(users.eve);

        // Make Eve the caller in this test.
        changePrank({ who: users.eve });

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
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
    function test_WithdrawMultiple_CallerApprovedOperator()
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
        callerAuthorizedAllStreams
    {
        // Approve the operator for all streams.
        lockup.setApprovalForAll(users.operator, true);

        // Make the operator the caller in this test.
        changePrank({ who: users.operator });

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Expect the withdrawals to be made.
        uint128 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT;
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount)));
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount)));

        // Make the withdrawals.
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });

        // Assert that the withdrawn amounts were updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount, "withdrawnAmount0");
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount, "withdrawnAmount1");
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

    /// @dev it should make the withdrawals, emit multiple {WithdrawFromLockupStream} events, and mark the streams as
    /// depleted.
    function test_WithdrawMultiple_AllStreamsEnded()
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
        callerAuthorizedAllStreams
        callerRecipient
        allAmountsNotZero
        allAmountsLessThanOrEqualToWithdrawableAmounts
    {
        // Warp into the future, past the stop time.
        vm.warp({ timestamp: DEFAULT_STOP_TIME });

        // Make Alice the `to` address in this test.
        address to = users.alice;

        // Expect two {WithdrawFromLockupStream} events to be emitted.
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
        assertEq(actualStatus0, expectedStatus, "status0");
        assertEq(actualStatus1, expectedStatus, "status1");

        // Assert that the NFTs weren't burned.
        address actualNFTOwner0 = lockup.ownerOf(defaultStreamIds[0]);
        address actualNFTOwner1 = lockup.ownerOf(defaultStreamIds[1]);
        address actualNFTOwner = users.recipient;
        assertEq(actualNFTOwner0, actualNFTOwner, "NFT owner0");
        assertEq(actualNFTOwner1, actualNFTOwner, "NFT owner1");
    }

    /// @dev it should make the withdrawals, emit multiple {WithdrawFromLockupStream} events, and update the withdrawn
    /// amounts.
    function test_WithdrawMultiple_AllStreamsOngoing()
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
        callerAuthorizedAllStreams
        callerRecipient
        allAmountsNotZero
        allAmountsLessThanOrEqualToWithdrawableAmounts
    {
        // Warp into the future, before the stop time of the streams.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Make Alice the `to` address in this test.
        address to = users.alice;

        // Set the withdraw amount to the streamed amount.
        uint128 withdrawAmount = lockup.getStreamedAmount(defaultStreamIds[0]);

        // Expect the withdrawals to be made.
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));

        // Expect two {WithdrawFromLockupStream} events to be emitted.
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
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount, "withdrawnAmount0");
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount, "withdrawnAmount1");
    }

    struct Vars {
        address actualEndedNFTOwner;
        Status actualStatus0;
        Status actualStatus1;
        uint128 actualWithdrawnAmount0;
        uint128 actualWithdrawnAmount1;
        uint128[] amounts;
        uint256 endedStreamId;
        uint128 endedWithdrawAmount;
        address expectedEndedNFTOwner;
        Status expectedStatus0;
        Status expectedStatus1;
        uint128 expectedWithdrawnAmount0;
        uint128 expectedWithdrawnAmount1;
        uint40 ongoingStopTime;
        uint256 ongoingStreamId;
        uint128 ongoingWithdrawAmount;
        uint256[] streamIds;
        address to;
    }

    /// @dev it should make the withdrawals, emit multiple {WithdrawFromLockupStream} events, mark the ended streams as
    /// depleted, and update the withdrawn amounts.
    function test_WithdrawMultiple_SomeStreamsEndedSomeStreamsOngoing()
        external
        toNonZeroAddress
        arraysEqual
        onlyNonNullStreams
        callerAuthorizedAllStreams
        callerRecipient
        allAmountsNotZero
        allAmountsLessThanOrEqualToWithdrawableAmounts
    {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_STOP_TIME });

        // Make Alice the `to` address in this test.
        Vars memory vars;
        vars.to = users.alice;

        // Use the first default stream as the ended stream.
        vars.endedStreamId = defaultStreamIds[0];
        vars.endedWithdrawAmount = DEFAULT_NET_DEPOSIT_AMOUNT;

        // Create a new stream with a stop time nearly double that of the default stream.
        vars.ongoingStopTime = DEFAULT_STOP_TIME + DEFAULT_TOTAL_DURATION;
        vars.ongoingStreamId = createDefaultStreamWithStopTime(vars.ongoingStopTime);

        // Get the ongoing withdraw amount.
        vars.ongoingWithdrawAmount = lockup.getWithdrawableAmount(vars.ongoingStreamId);

        // Expect two {WithdrawFromLockupStream} events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.WithdrawFromLockupStream({
            streamId: vars.endedStreamId,
            to: vars.to,
            amount: vars.endedWithdrawAmount
        });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.WithdrawFromLockupStream({
            streamId: vars.ongoingStreamId,
            to: vars.to,
            amount: vars.ongoingWithdrawAmount
        });

        // Run the test.
        vars.streamIds = Solarray.uint256s(vars.endedStreamId, vars.ongoingStreamId);
        vars.amounts = Solarray.uint128s(vars.endedWithdrawAmount, vars.ongoingWithdrawAmount);
        lockup.withdrawMultiple({ streamIds: vars.streamIds, to: vars.to, amounts: vars.amounts });

        // Assert that the ended stream was marked as depleted, and the ongoing stream was not.
        vars.actualStatus0 = lockup.getStatus(vars.endedStreamId);
        vars.actualStatus1 = lockup.getStatus(vars.ongoingStreamId);
        vars.expectedStatus0 = Status.DEPLETED;
        vars.expectedStatus1 = Status.ACTIVE;
        assertEq(vars.actualStatus0, vars.expectedStatus0, "status0");
        assertEq(vars.actualStatus1, vars.expectedStatus1, "status1");

        // Assert that the withdrawn amounts amounts were updated.
        vars.actualWithdrawnAmount0 = lockup.getWithdrawnAmount(vars.endedStreamId);
        vars.actualWithdrawnAmount1 = lockup.getWithdrawnAmount(vars.ongoingStreamId);
        vars.expectedWithdrawnAmount0 = vars.endedWithdrawAmount;
        vars.expectedWithdrawnAmount1 = vars.ongoingWithdrawAmount;
        assertEq(vars.actualWithdrawnAmount0, vars.expectedWithdrawnAmount0, "withdrawnAmount0");
        assertEq(vars.actualWithdrawnAmount1, vars.expectedWithdrawnAmount1, "withdrawnAmount1");

        // Assert that the ended stream NFT was not burned.
        vars.actualEndedNFTOwner = lockup.getRecipient(vars.endedStreamId);
        vars.expectedEndedNFTOwner = users.recipient;
        assertEq(vars.actualEndedNFTOwner, vars.expectedEndedNFTOwner, "NFT owner");
    }
}
