// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MAX_UD60x18, ud } from "@prb/math/src/UD60x18.sol";
import { stdError } from "forge-std/src/StdError.sol";

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Broker, Lockup, LockupTranched } from "src/core/types/DataTypes.sol";

import { Lockup_Integration_Shared_Test } from "./../../shared/lockup/Lockup.t.sol";

contract CreateWithTimestampsLT_Integration_Fuzz_Test is Lockup_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Lockup_Integration_Shared_Test.setUp();
        streamId = lockup.nextStreamId();
    }

    function testFuzz_RevertWhen_TrancheCountTooHigh(uint256 trancheCount)
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenTrancheCountNotZero
    {
        uint256 defaultMax = defaults.MAX_COUNT();
        trancheCount = _bound(trancheCount, defaultMax + 1, defaultMax * 10);
        LockupTranched.Tranche[] memory tranches = new LockupTranched.Tranche[](trancheCount);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_TrancheCountTooHigh.selector, trancheCount));
        createDefaultStreamWithTranchesLT(tranches);
    }

    function testFuzz_RevertWhen_TrancheAmountsSumOverflows(
        uint128 amount0,
        uint128 amount1
    )
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
    {
        amount0 = boundUint128(amount0, MAX_UINT128 / 2 + 1, MAX_UINT128);
        amount1 = boundUint128(amount0, MAX_UINT128 / 2 + 1, MAX_UINT128);
        LockupTranched.Tranche[] memory tranches = defaults.tranches();
        tranches[0].amount = amount0;
        tranches[1].amount = amount1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStreamWithTranchesLT(tranches);
    }

    function testFuzz_RevertWhen_StartTimeNotLessThanFirstTrancheTimestamp(uint40 firstTimestamp)
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
    {
        firstTimestamp = boundUint40(firstTimestamp, 0, defaults.START_TIME());

        // Change the timestamp of the first tranche.
        LockupTranched.Tranche[] memory tranches = defaults.tranches();
        tranches[0].timestamp = firstTimestamp;

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_StartTimeNotLessThanFirstTrancheTimestamp.selector,
                defaults.START_TIME(),
                tranches[0].timestamp
            )
        );

        // Create the stream.
        createDefaultStreamWithTranchesLT(tranches);
    }

    function testFuzz_RevertWhen_DepositAmountNotEqualToTrancheAmountsSum(uint128 depositDiff)
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenTrancheTimestampsAreOrdered
    {
        depositDiff = boundUint128(depositDiff, 100, defaults.TOTAL_AMOUNT());

        resetPrank({ msgSender: users.sender });

        // Adjust the default deposit amount.
        uint128 defaultDepositAmount = defaults.DEPOSIT_AMOUNT();
        uint128 depositAmount = defaultDepositAmount + depositDiff;

        // Prepare the params.
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestampsBrokerNull();
        params.totalAmount = depositAmount;
        LockupTranched.Tranche[] memory tranches = defaults.tranches();

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_DepositAmountNotEqualToTrancheAmountsSum.selector,
                depositAmount,
                defaultDepositAmount
            )
        );

        // Create the stream.
        lockup.createWithTimestampsLT(params, tranches);
    }

    function testFuzz_RevertWhen_BrokerFeeTooHigh(Broker memory broker)
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenTrancheTimestampsAreOrdered
        whenDepositAmountNotEqualTrancheAmountsSum
    {
        vm.assume(broker.account != address(0));
        broker.fee = _bound(broker.fee, MAX_BROKER_FEE + ud(1), MAX_UD60x18);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_BrokerFeeTooHigh.selector, broker.fee, MAX_BROKER_FEE)
        );
        createDefaultStreamWithBrokerLT(broker);
    }

    struct Vars {
        uint256 actualNextStreamId;
        address actualNFTOwner;
        Lockup.Status actualStatus;
        Lockup.CreateAmounts createAmounts;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        Lockup.Status expectedStatus;
        bool isCancelable;
        bool isSettled;
        uint128 totalAmount;
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - All possible permutations for the funder, sender, recipient, and broker
    /// - Multiple values for the tranche amounts, exponents, and timestamps
    /// - Cancelable and not cancelable
    /// - Start time in the past
    /// - Start time in the present
    /// - Start time in the future
    /// - Start time equal and not equal to the first tranche timestamp
    /// - Multiple values for the broker fee, including zero
    function testFuzz_CreateWithTimestampsLT(
        address funder,
        Lockup.CreateWithTimestamps memory params,
        LockupTranched.Tranche[] memory tranches
    )
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenTrancheTimestampsAreOrdered
        whenDepositAmountNotEqualTrancheAmountsSum
        whenBrokerFeeNotExceedMaxValue
        whenAssetContract
        whenAssetERC20
    {
        vm.assume(
            funder != address(0) && params.sender != address(0) && params.recipient != address(0)
                && params.broker.account != address(0)
        );
        vm.assume(tranches.length != 0);
        params.broker.fee = _bound(params.broker.fee, 0, MAX_BROKER_FEE);

        params.startTime = boundUint40(params.startTime, 1, defaults.START_TIME());
        params.transferable = true;

        // Fuzz the tranche timestamps.
        fuzzTrancheTimestamps(tranches, params.startTime);

        // Fuzz the tranche amounts and calculate the total and create amounts (deposit and broker fee).
        Vars memory vars;
        (vars.totalAmount, vars.createAmounts) =
            fuzzTranchedStreamAmounts({ upperBound: MAX_UINT128, tranches: tranches, brokerFee: params.broker.fee });

        // Make the fuzzed funder the caller in the rest of this test.
        resetPrank(funder);

        // Mint enough assets to the fuzzed funder.
        deal({ token: address(dai), to: funder, give: vars.totalAmount });

        // Approve {SablierLockupTranched} to transfer the assets from the fuzzed funder.
        dai.approve({ spender: address(lockup), value: MAX_UINT256 });

        // Expect the assets to be transferred from the funder to {SablierLockupTranched}.
        expectCallToTransferFrom({ from: funder, to: address(lockup), value: vars.createAmounts.deposit });

        // Expect the broker fee to be paid to the broker, if not zero.
        if (vars.createAmounts.brokerFee > 0) {
            expectCallToTransferFrom({ from: funder, to: params.broker.account, value: vars.createAmounts.brokerFee });
        }

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: params.startTime, cliff: 0, end: tranches[tranches.length - 1].timestamp });
        emit ISablierLockup.CreateLockupTranchedStream({
            streamId: streamId,
            funder: funder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: vars.createAmounts,
            asset: dai,
            cancelable: params.cancelable,
            transferable: params.transferable,
            tranches: tranches,
            timestamps: timestamps,
            broker: params.broker.account
        });

        // Create the stream.
        lockup.createWithTimestampsLT(
            Lockup.CreateWithTimestamps({
                sender: params.sender,
                recipient: params.recipient,
                totalAmount: vars.totalAmount,
                asset: dai,
                cancelable: params.cancelable,
                transferable: params.transferable,
                startTime: params.startTime,
                endTime: tranches[tranches.length - 1].timestamp,
                broker: params.broker
            }),
            tranches
        );

        // Check if the stream is settled. It is possible for a Lockup Tranched stream to settle at the time of creation
        // because some tranche amounts can be zero.
        vars.isSettled = (lockup.getDepositedAmount(streamId) - lockup.streamedAmountOf(streamId)) == 0;
        vars.isCancelable = vars.isSettled ? false : params.cancelable;

        // It should create the stream.
        assertEq(lockup.getDepositedAmount(streamId), vars.createAmounts.deposit, "depositedAmount");
        assertEq(lockup.getAsset(streamId), dai, "asset");
        assertEq(lockup.getEndTime(streamId), timestamps.end, "endTime");
        assertEq(lockup.isCancelable(streamId), vars.isCancelable, "isCancelable");
        assertEq(lockup.isDepleted(streamId), false, "isDepleted");
        assertEq(lockup.isStream(streamId), true, "isStream");
        assertEq(lockup.isTransferable(streamId), true, "isTransferable");
        assertEq(lockup.getRecipient(streamId), params.recipient, "recipient");
        assertEq(lockup.getSender(streamId), params.sender, "sender");
        assertEq(lockup.getStartTime(streamId), timestamps.start, "startTime");
        assertEq(lockup.wasCanceled(streamId), false, "wasCanceled");
        assertEq(lockup.getTranches(streamId), tranches, "tranches");

        // Assert that the stream's status is correct.
        vars.actualStatus = lockup.statusOf(streamId);
        if (params.startTime > getBlockTimestamp()) {
            vars.expectedStatus = Lockup.Status.PENDING;
        } else if (vars.isSettled) {
            vars.expectedStatus = Lockup.Status.SETTLED;
        } else {
            vars.expectedStatus = Lockup.Status.STREAMING;
        }
        assertEq(vars.actualStatus, vars.expectedStatus);

        // Assert that the next stream ID has been bumped.
        vars.actualNextStreamId = lockup.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
