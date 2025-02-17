// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { stdError } from "forge-std/src/StdError.sol";

import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupTranched } from "src/types/DataTypes.sol";

import { Lockup_Tranched_Integration_Fuzz_Test } from "./LockupTranched.t.sol";

contract CreateWithTimestampsLT_Integration_Fuzz_Test is Lockup_Tranched_Integration_Fuzz_Test {
    function testFuzz_RevertWhen_ShapeExceeds32Bytes(string memory shapeName)
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
    {
        vm.assume(bytes(shapeName).length > 32);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierHelpers_ShapeExceeds32Bytes.selector, bytes(shapeName).length)
        );

        _defaultParams.createWithTimestamps.shape = shapeName;
        createDefaultStream();
    }

    function testFuzz_RevertWhen_TrancheCountTooHigh(uint256 trancheCount)
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenTrancheCountNotZero
    {
        uint256 defaultMax = defaults.MAX_COUNT();
        trancheCount = _bound(trancheCount, defaultMax + 1, defaultMax * 10);
        LockupTranched.Tranche[] memory tranches = new LockupTranched.Tranche[](trancheCount);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierHelpers_TrancheCountTooHigh.selector, trancheCount));
        lockup.createWithTimestampsLT(_defaultParams.createWithTimestamps, tranches);
    }

    function testFuzz_RevertWhen_TrancheAmountsSumOverflows(
        uint128 amount0,
        uint128 amount1
    )
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
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
        lockup.createWithTimestampsLT(_defaultParams.createWithTimestamps, tranches);
    }

    function testFuzz_RevertWhen_StartTimeNotLessThanFirstTrancheTimestamp(uint40 firstTimestamp)
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
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
                Errors.SablierHelpers_StartTimeNotLessThanFirstTrancheTimestamp.selector,
                defaults.START_TIME(),
                tranches[0].timestamp
            )
        );
        lockup.createWithTimestampsLT(_defaultParams.createWithTimestamps, tranches);
    }

    function testFuzz_RevertWhen_DepositAmountNotEqualToTrancheAmountsSum(uint128 depositDiff)
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenTrancheTimestampsAreOrdered
    {
        depositDiff = boundUint128(depositDiff, 100, defaults.DEPOSIT_AMOUNT());

        resetPrank({ msgSender: users.sender });

        // Adjust the default deposit amount.
        uint128 defaultDepositAmount = defaults.DEPOSIT_AMOUNT();
        uint128 depositAmount = defaultDepositAmount + depositDiff;

        // Prepare the params.
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestamps();
        params.depositAmount = depositAmount;
        LockupTranched.Tranche[] memory tranches = defaults.tranches();

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_DepositAmountNotEqualToTrancheAmountsSum.selector,
                depositAmount,
                defaultDepositAmount
            )
        );

        lockup.createWithTimestampsLT(params, tranches);
    }

    struct Vars {
        uint256 actualNextStreamId;
        address actualNFTOwner;
        Lockup.Status actualStatus;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        Lockup.Status expectedStatus;
        bool isCancelable;
        bool isSettled;
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - All possible permutations for the funder, sender and recipient
    /// - Multiple values for the tranche amounts, exponents, and timestamps
    /// - Cancelable and not cancelable
    /// - Start time in the past
    /// - Start time in the present
    /// - Start time in the future
    /// - Start time equal and not equal to the first tranche timestamp
    function testFuzz_CreateWithTimestampsLT(
        address funder,
        Lockup.CreateWithTimestamps memory params,
        LockupTranched.Tranche[] memory tranches
    )
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
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
        whenTokenContract
        whenTokenERC20
    {
        vm.assume(funder != address(0) && params.sender != address(0) && params.recipient != address(0));
        vm.assume(tranches.length != 0);

        params.token = dai;
        params.timestamps.start = boundUint40(params.timestamps.start, 1, defaults.START_TIME());
        params.transferable = true;

        // If shape exceeds 32 bytes, use the default value.
        if (bytes(params.shape).length > 32) params.shape = defaults.SHAPE();

        // Fuzz the tranche timestamps.
        fuzzTrancheTimestamps(tranches, params.timestamps.start);
        params.timestamps.end = tranches[tranches.length - 1].timestamp;

        params.depositAmount = fuzzTranchedStreamAmounts({ upperBound: MAX_UINT128, tranches: tranches });

        // Make the fuzzed funder the caller in the rest of this test.
        resetPrank(funder);

        // Mint enough tokens to the fuzzed funder.
        deal({ token: address(dai), to: funder, give: params.depositAmount });

        // Approve {SablierLockup} to transfer the tokens from the fuzzed funder.
        dai.approve({ spender: address(lockup), value: MAX_UINT256 });

        // Expect the tokens to be transferred from the funder to {SablierLockup}.
        expectCallToTransferFrom({ from: funder, to: address(lockup), value: params.depositAmount });

        uint256 expectedStreamId = lockup.nextStreamId();

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupTranchedStream({
            streamId: expectedStreamId,
            commonParams: Lockup.CreateEventCommon({
                funder: funder,
                sender: params.sender,
                recipient: params.recipient,
                depositAmount: params.depositAmount,
                token: dai,
                cancelable: params.cancelable,
                transferable: params.transferable,
                timestamps: params.timestamps,
                shape: params.shape
            }),
            tranches: tranches
        });

        // Create the stream.
        uint256 streamId = lockup.createWithTimestampsLT(params, tranches);

        // Fuzz the tranche amounts and calculate the deposit amount.
        Vars memory vars;

        // Check if the stream is settled. It is possible for a stream to settle at the time of creation because some
        // tranche amounts can be zero.
        vars.isSettled = (lockup.getDepositedAmount(streamId) - lockup.streamedAmountOf(streamId)) == 0;
        vars.isCancelable = vars.isSettled ? false : params.cancelable;

        // It should create the stream.
        assertEq(lockup.getDepositedAmount(streamId), params.depositAmount, "depositedAmount");
        assertEq(lockup.getEndTime(streamId), params.timestamps.end, "endTime");
        assertEq(lockup.isCancelable(streamId), vars.isCancelable, "isCancelable");
        assertFalse(lockup.isDepleted(streamId), "isDepleted");
        assertTrue(lockup.isStream(streamId), "isStream");
        assertTrue(lockup.isTransferable(streamId), "isTransferable");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_TRANCHED);
        assertEq(lockup.getRecipient(streamId), params.recipient, "recipient");
        assertEq(lockup.getSender(streamId), params.sender, "sender");
        assertEq(lockup.getStartTime(streamId), params.timestamps.start, "startTime");
        assertEq(lockup.getTranches(streamId), tranches);
        assertEq(lockup.getUnderlyingToken(streamId), dai, "underlyingToken");
        assertFalse(lockup.wasCanceled(streamId), "wasCanceled");

        // Assert that the stream's status is correct.
        vars.actualStatus = lockup.statusOf(streamId);
        if (params.timestamps.start > getBlockTimestamp()) {
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
