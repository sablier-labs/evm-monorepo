// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../../Fuzz.t.sol";

abstract contract WithdrawMultiple_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint128[] internal defaultAmounts;
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        // Define the default amounts, since most tests need them.
        defaultAmounts.push(DEFAULT_WITHDRAW_AMOUNT);
        defaultAmounts.push(DEFAULT_WITHDRAW_AMOUNT);

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the caller in this test suite.
        changePrank({ msgSender: users.recipient });
    }

    modifier toNonZeroAddress() {
        _;
    }

    modifier arraysEqual() {
        _;
    }

    modifier onlyNonNullStreams() {
        _;
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
        changePrank({ msgSender: users.operator });

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Expect the withdrawals to be made.
        uint128 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT;
        expectTransferCall({ to: to, amount: withdrawAmount });
        expectTransferCall({ to: to, amount: withdrawAmount });

        // Make the withdrawals.
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: defaultAmounts });

        // Assert that the withdrawn amounts have been updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount, "withdrawnAmount0");
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount, "withdrawnAmount1");
    }

    modifier callerRecipient() {
        _;
    }

    modifier allAmountsNotZero() {
        _;
    }
    modifier allAmountsLessThanOrEqualToWithdrawableAmounts() {
        _;
    }

    /// @dev it should make the withdrawals, emit multiple {WithdrawFromLockupStream} events, and mark the streams as
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
        vm.assume(to != address(0));
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);

        // Warp into the future, past the end time.
        vm.warp({ timestamp: DEFAULT_END_TIME + timeWarp });

        // Expect two {WithdrawFromLockupStream} events to be emitted.
        expectEmit();
        emit Events.WithdrawFromLockupStream({ streamId: defaultStreamIds[0], to: to, amount: DEFAULT_DEPOSIT_AMOUNT });
        expectEmit();
        emit Events.WithdrawFromLockupStream({ streamId: defaultStreamIds[1], to: to, amount: DEFAULT_DEPOSIT_AMOUNT });

        // Expect the withdrawals to be made.
        expectTransferCall({ to: to, amount: DEFAULT_DEPOSIT_AMOUNT });
        expectTransferCall({ to: to, amount: DEFAULT_DEPOSIT_AMOUNT });

        // Make the withdrawals.
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_DEPOSIT_AMOUNT, DEFAULT_DEPOSIT_AMOUNT);
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: amounts });

        // Assert that the streams have been marked as depleted.
        Lockup.Status actualStatus0 = lockup.getStatus(defaultStreamIds[0]);
        Lockup.Status actualStatus1 = lockup.getStatus(defaultStreamIds[1]);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus0, expectedStatus, "status0");
        assertEq(actualStatus1, expectedStatus, "status1");

        // Assert that the withdrawn amounts have been updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = DEFAULT_DEPOSIT_AMOUNT;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount, "withdrawnAmount0");
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount, "withdrawnAmount1");

        // Assert that the NFTs have not been burned.
        address actualNFTOwner0 = lockup.ownerOf(defaultStreamIds[0]);
        address actualNFTOwner1 = lockup.ownerOf(defaultStreamIds[1]);
        address actualNFTOwner = users.recipient;
        assertEq(actualNFTOwner0, actualNFTOwner, "NFT owner0");
        assertEq(actualNFTOwner1, actualNFTOwner, "NFT owner1");
    }

    /// @dev it should make the withdrawals, emit multiple {WithdrawFromLockupStream} events, and update the withdrawn
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
        vm.assume(to != address(0));
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Warp into the future, before the end time of the stream.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the withdraw amount.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(defaultStreamIds[0]);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Expect the withdrawals to be made.
        expectTransferCall({ to: to, amount: withdrawAmount });
        expectTransferCall({ to: to, amount: withdrawAmount });

        // Expect two {WithdrawFromLockupStream} events to be emitted.
        expectEmit();
        emit Events.WithdrawFromLockupStream({ streamId: defaultStreamIds[0], to: to, amount: withdrawAmount });
        expectEmit();
        emit Events.WithdrawFromLockupStream({ streamId: defaultStreamIds[1], to: to, amount: withdrawAmount });

        // Make the withdrawals.
        uint128[] memory amounts = Solarray.uint128s(withdrawAmount, withdrawAmount);
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: amounts });

        // Assert that the streams have remained active.
        Lockup.Status actualStatus0 = lockup.getStatus(defaultStreamIds[0]);
        Lockup.Status actualStatus1 = lockup.getStatus(defaultStreamIds[1]);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus0, expectedStatus, "status0");
        assertEq(actualStatus1, expectedStatus, "status1");

        // Assert that the withdrawn amounts have been updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount, "withdrawnAmount0");
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount, "withdrawnAmount1");
    }

    struct Params {
        uint128 ongoingWithdrawAmount;
        uint256 timeWarp;
        address to;
    }

    struct Vars {
        address actualEndedNFTOwner;
        Lockup.Status actualStatus0;
        Lockup.Status actualStatus1;
        uint128 actualWithdrawnAmount0;
        uint128 actualWithdrawnAmount1;
        uint128[] amounts;
        uint256 endedStreamId;
        uint128 endedWithdrawAmount;
        address expectedEndedNFTOwner;
        Lockup.Status expectedStatus0;
        Lockup.Status expectedStatus1;
        uint128 expectedWithdrawnAmount0;
        uint128 expectedWithdrawnAmount1;
        uint40 ongoingEndTime;
        uint256 ongoingStreamId;
        uint128 ongoingWithdrawableAmount;
        uint256[] streamIds;
        address to;
    }

    /// @dev it should make the withdrawals, emit multiple {WithdrawFromLockupStream} events, mark the ended streams as
    /// depleted, and update the withdrawn amounts.
    function testFuzz_WithdrawMultiple_SomeStreamsEndedSomeStreamsOngoing(
        Params memory params
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
        vm.assume(params.to != address(0));
        params.timeWarp = bound(params.timeWarp, DEFAULT_TOTAL_DURATION, DEFAULT_TOTAL_DURATION * 2 - 1);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + params.timeWarp });

        // Use the first default stream as the ended stream.
        Vars memory vars;
        vars.endedStreamId = defaultStreamIds[0];
        vars.endedWithdrawAmount = DEFAULT_DEPOSIT_AMOUNT;

        // Create a new stream with an end time nearly double that of the default stream.
        vars.ongoingEndTime = DEFAULT_END_TIME + DEFAULT_TOTAL_DURATION;
        vars.ongoingStreamId = createDefaultStreamWithEndTime(vars.ongoingEndTime);

        // Bound the ongoing withdraw amount.
        vars.ongoingWithdrawableAmount = lockup.withdrawableAmountOf(vars.ongoingStreamId);
        params.ongoingWithdrawAmount = boundUint128(params.ongoingWithdrawAmount, 1, vars.ongoingWithdrawableAmount);

        // Expect two {WithdrawFromLockupStream} events to be emitted.
        expectEmit();
        emit Events.WithdrawFromLockupStream({
            streamId: vars.endedStreamId,
            to: params.to,
            amount: vars.endedWithdrawAmount
        });
        expectEmit();
        emit Events.WithdrawFromLockupStream({
            streamId: vars.ongoingStreamId,
            to: params.to,
            amount: params.ongoingWithdrawAmount
        });

        // Run the test.
        vars.streamIds = Solarray.uint256s(vars.endedStreamId, vars.ongoingStreamId);
        vars.amounts = Solarray.uint128s(vars.endedWithdrawAmount, params.ongoingWithdrawAmount);
        lockup.withdrawMultiple({ streamIds: vars.streamIds, to: params.to, amounts: vars.amounts });

        // Assert that the ended stream has been marked as depleted, and the ongoing stream has not been.
        vars.actualStatus0 = lockup.getStatus(vars.endedStreamId);
        vars.actualStatus1 = lockup.getStatus(vars.ongoingStreamId);
        vars.expectedStatus0 = Lockup.Status.DEPLETED;
        vars.expectedStatus1 = Lockup.Status.ACTIVE;
        assertEq(vars.actualStatus0, vars.expectedStatus0, "status0");
        assertEq(vars.actualStatus1, vars.expectedStatus1, "status1");

        // Assert that the withdrawn amounts amounts have been updated.
        vars.actualWithdrawnAmount0 = lockup.getWithdrawnAmount(vars.endedStreamId);
        vars.actualWithdrawnAmount1 = lockup.getWithdrawnAmount(vars.ongoingStreamId);
        vars.expectedWithdrawnAmount0 = vars.endedWithdrawAmount;
        vars.expectedWithdrawnAmount1 = params.ongoingWithdrawAmount;
        assertEq(vars.actualWithdrawnAmount0, vars.expectedWithdrawnAmount0, "withdrawnAmount0");
        assertEq(vars.actualWithdrawnAmount1, vars.expectedWithdrawnAmount1, "withdrawnAmount1");

        // Assert that the ended stream NFT has not been burned.
        vars.actualEndedNFTOwner = lockup.getRecipient(vars.endedStreamId);
        vars.expectedEndedNFTOwner = users.recipient;
        assertEq(vars.actualEndedNFTOwner, vars.expectedEndedNFTOwner, "NFT owner");
    }
}
