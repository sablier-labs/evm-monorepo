// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { MAX_UD60x18, UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { ISablierV2LockupDynamic } from "src/interfaces/ISablierV2LockupDynamic.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Broker, Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { CreateWithMilestones_Dynamic_Shared_Test } from
    "../../../shared/lockup-dynamic/create-with-milestones/createWithMilestones.t.sol";
import { Dynamic_Fuzz_Test } from "../Dynamic.t.sol";

contract CreateWithMilestones_Dynamic_Fuzz_Test is Dynamic_Fuzz_Test, CreateWithMilestones_Dynamic_Shared_Test {
    function setUp() public virtual override(Dynamic_Fuzz_Test, CreateWithMilestones_Dynamic_Shared_Test) {
        Dynamic_Fuzz_Test.setUp();
        CreateWithMilestones_Dynamic_Shared_Test.setUp();
    }

    function testFuzz_RevertWhen_SegmentCountTooHigh(uint256 segmentCount)
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
    {
        segmentCount = bound(segmentCount, defaults.MAX_SEGMENT_COUNT() + 1, defaults.MAX_SEGMENT_COUNT() * 10);
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](segmentCount);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2LockupDynamic_SegmentCountTooHigh.selector, segmentCount)
        );
        createDefaultStreamWithSegments(segments);
    }

    function testFuzz_RevertWhen_SegmentAmountsSumOverflows(
        uint128 amount0,
        uint128 amount1
    )
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
    {
        amount0 = boundUint128(amount0, MAX_UINT128 / 2 + 1, MAX_UINT128);
        amount1 = boundUint128(amount0, MAX_UINT128 / 2 + 1, MAX_UINT128);
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].amount = amount0;
        segments[1].amount = amount1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStreamWithSegments(segments);
    }

    function testFuzz_RevertWhen_StartTimeNotLessThanFirstSegmentMilestone(uint40 firstMilestone)
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
    {
        firstMilestone = boundUint40(firstMilestone, 0, defaults.START_TIME());

        // Change the milestone of the first segment.
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].milestone = firstMilestone;

        // Expect a {StartTimeNotLessThanFirstSegmentMilestone} error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupDynamic_StartTimeNotLessThanFirstSegmentMilestone.selector,
                defaults.START_TIME(),
                segments[0].milestone
            )
        );

        // Create the stream.
        createDefaultStreamWithSegments(segments);
    }

    function testFuzz_RevertWhen_DepositAmountNotEqualToSegmentAmountsSum(uint128 depositDiff)
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenSegmentMilestonesOrdered
        whenStartTimeLessThanFirstSegmentMilestone
    {
        depositDiff = boundUint128(depositDiff, 100, defaults.TOTAL_AMOUNT());

        // Disable both the protocol and the broker fee so that they don't interfere with the calculations.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: dai, newProtocolFee: ZERO });
        UD60x18 brokerFee = ZERO;
        changePrank({ msgSender: users.sender });

        // Adjust the default deposit amount.
        uint128 defaultDepositAmount = defaults.DEPOSIT_AMOUNT();
        uint128 depositAmount = defaultDepositAmount + depositDiff;

        // Prepare the params.
        LockupDynamic.CreateWithMilestones memory params = defaults.createWithMilestones();
        params.broker = Broker({ account: address(0), fee: brokerFee });
        params.totalAmount = depositAmount;

        // Expect a {DepositAmountNotEqualToSegmentAmountsSum} error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupDynamic_DepositAmountNotEqualToSegmentAmountsSum.selector,
                depositAmount,
                defaultDepositAmount
            )
        );

        // Create the stream.
        dynamic.createWithMilestones(params);
    }

    function testFuzz_RevertWhen_ProtocolFeeTooHigh(UD60x18 protocolFee)
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenSegmentMilestonesOrdered
        whenStartTimeLessThanFirstSegmentMilestone
        whenDepositAmountEqualToSegmentAmountsSum
    {
        protocolFee = bound(protocolFee, MAX_FEE + ud(1), MAX_UD60x18);

        // Set the protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: dai, newProtocolFee: protocolFee });
        changePrank({ msgSender: users.sender });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_ProtocolFeeTooHigh.selector, protocolFee, MAX_FEE)
        );
        createDefaultStream();
    }

    function testFuzz_RevertWhen_BrokerFeeTooHigh(Broker memory broker)
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenSegmentMilestonesOrdered
        whenStartTimeLessThanFirstSegmentMilestone
        whenDepositAmountEqualToSegmentAmountsSum
        whenProtocolFeeNotTooHigh
    {
        vm.assume(broker.account != address(0));
        broker.fee = bound(broker.fee, MAX_FEE + ud(1), MAX_UD60x18);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, broker.fee, MAX_FEE));
        createDefaultStreamWithBroker(broker);
    }

    struct Vars {
        uint256 actualNextStreamId;
        address actualNFTOwner;
        uint256 actualProtocolRevenues;
        Lockup.Status actualStatus;
        Lockup.CreateAmounts createAmounts;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        uint256 expectedProtocolRevenues;
        Lockup.Status expectedStatus;
        bool isSettled;
        uint128 totalAmount;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - All possible permutations for the funder, sender, recipient, and broker
    /// - Multiple values for the segment amounts, exponents, and milestones
    /// - Cancelable and not cancelable
    /// - Start time in the past, present and future
    /// - Start time equal and not equal to the first segment milestone
    /// - Multiple values for the broker fee, including zero
    /// - Multiple values for the protocol fee, including zero
    function testFuzz_CreateWithMilestones(
        address funder,
        LockupDynamic.CreateWithMilestones memory params,
        UD60x18 protocolFee
    )
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenSegmentMilestonesOrdered
        whenStartTimeLessThanFirstSegmentMilestone
        whenDepositAmountEqualToSegmentAmountsSum
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
        whenAssetContract
        whenAssetERC20Compliant
    {
        vm.assume(funder != address(0) && params.recipient != address(0) && params.broker.account != address(0));
        vm.assume(params.segments.length != 0);
        params.broker.fee = bound(params.broker.fee, 0, MAX_FEE);
        protocolFee = bound(protocolFee, 0, MAX_FEE);
        params.startTime = boundUint40(params.startTime, 0, defaults.START_TIME());

        // Fuzz the segment milestones.
        fuzzSegmentMilestones(params.segments, params.startTime);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        Vars memory vars;
        (vars.totalAmount, vars.createAmounts) = fuzzDynamicStreamAmounts({
            upperBound: MAX_UINT128,
            segments: params.segments,
            protocolFee: protocolFee,
            brokerFee: params.broker.fee
        });

        // Set the fuzzed protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: dai, newProtocolFee: protocolFee });

        // Make the fuzzed funder the caller in the rest of this test.
        changePrank(funder);

        // Mint enough assets to the fuzzed funder.
        deal({ token: address(dai), to: funder, give: vars.totalAmount });

        // Approve {SablierV2LockupDynamic} to transfer the assets from the fuzzed funder.
        dai.approve({ spender: address(dynamic), amount: MAX_UINT256 });

        // Expect the assets to be transferred from the funder to {SablierV2LockupDynamic}.
        expectCallToTransferFrom({
            from: funder,
            to: address(dynamic),
            amount: vars.createAmounts.deposit + vars.createAmounts.protocolFee
        });

        // Expect the broker fee to be paid to the broker, if not zero.
        if (vars.createAmounts.brokerFee > 0) {
            expectCallToTransferFrom({ from: funder, to: params.broker.account, amount: vars.createAmounts.brokerFee });
        }

        // Expect a {CreateLockupDynamicStream} event to be emitted.
        vm.expectEmit({ emitter: address(dynamic) });
        LockupDynamic.Range memory range =
            LockupDynamic.Range({ start: params.startTime, end: params.segments[params.segments.length - 1].milestone });
        emit CreateLockupDynamicStream({
            streamId: streamId,
            funder: funder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: vars.createAmounts,
            asset: dai,
            cancelable: params.cancelable,
            segments: params.segments,
            range: range,
            broker: params.broker.account
        });

        // Create the stream.
        dynamic.createWithMilestones(
            LockupDynamic.CreateWithMilestones({
                asset: dai,
                broker: params.broker,
                cancelable: params.cancelable,
                recipient: params.recipient,
                segments: params.segments,
                sender: params.sender,
                startTime: params.startTime,
                totalAmount: vars.totalAmount
            })
        );

        // Assert that the stream has been created.
        LockupDynamic.Stream memory actualStream = dynamic.getStream(streamId);
        assertEq(actualStream.amounts, Lockup.Amounts(vars.createAmounts.deposit, 0, 0));
        assertEq(actualStream.asset, dai, "asset");
        assertEq(actualStream.endTime, range.end, "endTime");
        assertEq(actualStream.isCancelable, params.cancelable, "isCancelable");
        assertEq(actualStream.isDepleted, false, "isStream");
        assertEq(actualStream.isStream, true, "isStream");
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.segments, params.segments, "segments");
        assertEq(actualStream.startTime, range.start, "startTime");
        assertEq(actualStream.wasCanceled, false, "wasCanceled");

        // Check if the stream is settled. It is possible for a dynamic stream to settle at the time of creation
        // because some segment amounts can be zero.
        vars.isSettled = dynamic.refundableAmountOf(streamId) == 0;

        // Assert that the stream's status is correct.
        vars.actualStatus = dynamic.statusOf(streamId);
        vars.expectedStatus = vars.isSettled ? Lockup.Status.SETTLED : Lockup.Status.STREAMING;
        assertEq(vars.actualStatus, vars.expectedStatus);

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = dynamic.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = dynamic.protocolRevenues(dai);
        vars.expectedProtocolRevenues = vars.createAmounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = dynamic.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
