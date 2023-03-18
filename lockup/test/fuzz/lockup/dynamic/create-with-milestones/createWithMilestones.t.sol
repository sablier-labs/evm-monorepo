// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { MAX_UD60x18, UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { ISablierV2LockupDynamic } from "src/interfaces/ISablierV2LockupDynamic.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Broker, Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Fuzz_Test } from "../Dynamic.t.sol";

contract CreateWithMilestones_Dynamic_Fuzz_Test is Dynamic_Fuzz_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        super.setUp();

        // Load the stream id.
        streamId = dynamic.nextStreamId();
    }

    modifier whenRecipientNonZeroAddress() {
        _;
    }

    modifier whenDepositAmountNotZero() {
        _;
    }

    modifier whenSegmentCountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_SegmentCountTooHigh(uint256 segmentCount)
        external
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
    {
        segmentCount = bound(segmentCount, DEFAULT_MAX_SEGMENT_COUNT + 1, DEFAULT_MAX_SEGMENT_COUNT * 10);
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](segmentCount);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2LockupDynamic_SegmentCountTooHigh.selector, segmentCount)
        );
        createDefaultStreamWithSegments(segments);
    }

    modifier whenSegmentCountNotTooHigh() {
        _;
    }

    /// @dev When the segment amounts sum overflows, it should revert.
    function testFuzz_RevertWhen_SegmentAmountsSumOverflows(
        uint128 amount0,
        uint128 amount1
    )
        external
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
    {
        amount0 = boundUint128(amount0, UINT128_MAX / 2 + 1, UINT128_MAX);
        amount1 = boundUint128(amount0, UINT128_MAX / 2 + 1, UINT128_MAX);
        LockupDynamic.Segment[] memory segments = DEFAULT_SEGMENTS;
        segments[0].amount = amount0;
        segments[1].amount = amount1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStreamWithSegments(segments);
    }

    modifier whenSegmentAmountsSumDoesNotOverflow() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_StartTimeNotLessThanFirstSegmentMilestone(uint40 firstMilestone)
        external
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
    {
        firstMilestone = boundUint40(firstMilestone, 0, DEFAULT_START_TIME);

        // Change the milestone of the first segment.
        LockupDynamic.Segment[] memory segments = DEFAULT_SEGMENTS;
        segments[0].milestone = firstMilestone;

        // Expect a {StartTimeNotLessThanFirstSegmentMilestone} error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupDynamic_StartTimeNotLessThanFirstSegmentMilestone.selector,
                DEFAULT_START_TIME,
                segments[0].milestone
            )
        );

        // Create the stream.
        createDefaultStreamWithSegments(segments);
    }

    modifier whenStartTimeLessThanFirstSegmentMilestone() {
        _;
    }

    modifier whenSegmentMilestonesOrdered() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_DepositAmountNotEqualToSegmentAmountsSum(uint128 depositDiff)
        external
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenSegmentMilestonesOrdered
        whenStartTimeLessThanFirstSegmentMilestone
    {
        depositDiff = boundUint128(depositDiff, 100, DEFAULT_TOTAL_AMOUNT);

        // Disable both the protocol and the broker fee so that they don't interfere with the calculations.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        UD60x18 brokerFee = ZERO;
        changePrank(defaultParams.createWithMilestones.sender);

        // Adjust the default deposit amount.
        uint128 depositAmount = DEFAULT_DEPOSIT_AMOUNT + depositDiff;

        // Expect a {DepositAmountNotEqualToSegmentAmountsSum} error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupDynamic_DepositAmountNotEqualToSegmentAmountsSum.selector,
                depositAmount,
                DEFAULT_DEPOSIT_AMOUNT
            )
        );

        // Create the stream.
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.totalAmount = depositAmount;
        params.broker = Broker({ account: address(0), fee: brokerFee });
        dynamic.createWithMilestones(params);
    }

    modifier whenDepositAmountEqualToSegmentAmountsSum() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_ProtocolFeeTooHigh(UD60x18 protocolFee)
        external
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenSegmentMilestonesOrdered
        whenStartTimeLessThanFirstSegmentMilestone
        whenDepositAmountEqualToSegmentAmountsSum
    {
        protocolFee = bound(protocolFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);

        // Set the protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee(defaultStream.asset, protocolFee);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_ProtocolFeeTooHigh.selector, protocolFee, DEFAULT_MAX_FEE)
        );
        createDefaultStream();
    }

    modifier whenProtocolFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_BrokerFeeTooHigh(Broker memory broker)
        external
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
        broker.fee = bound(broker.fee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, broker.fee, DEFAULT_MAX_FEE)
        );
        createDefaultStreamWithBroker(broker);
    }

    modifier whenBrokerFeeNotTooHigh() {
        _;
    }

    modifier whenAssetContract() {
        _;
    }

    modifier whenAssetERC20Compliant() {
        _;
    }

    struct Vars {
        uint256 actualNextStreamId;
        address actualNFTOwner;
        uint256 actualProtocolRevenues;
        Lockup.CreateAmounts createAmounts;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        uint256 expectedProtocolRevenues;
        uint128 totalAmount;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, record the protocol
    /// fee, mint the NFT, and emit a {CreateLockupDynamicStream} event.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, sender, recipient, and broker.
    /// - Multiple values for the segment amounts, exponents, and milestones.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time equal and not equal to the first segment milestone.
    /// - Multiple values for the broker fee, including zero.
    /// - Multiple values for the protocol fee, including zero.
    function testFuzz_CreateWithMilestones(
        address funder,
        LockupDynamic.CreateWithMilestones memory params,
        UD60x18 protocolFee
    )
        external
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
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        protocolFee = bound(protocolFee, 0, DEFAULT_MAX_FEE);
        params.startTime = boundUint40(params.startTime, 0, DEFAULT_START_TIME);

        // Fuzz the segment milestones.
        fuzzSegmentMilestones(params.segments, params.startTime);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        Vars memory vars;
        (vars.totalAmount, vars.createAmounts) = fuzzSegmentAmountsAndCalculateCreateAmounts({
            upperBound: UINT128_MAX,
            segments: params.segments,
            protocolFee: protocolFee,
            brokerFee: params.broker.fee
        });

        // Set the fuzzed protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: protocolFee });

        // Make the fuzzed funder the caller in the rest of this test.
        changePrank(funder);

        // Mint enough ERC-20 assets to the fuzzed funder.
        deal({ token: address(DEFAULT_ASSET), to: funder, give: vars.totalAmount });

        // Approve {SablierV2LockupDynamic} to transfer the ERC-20 assets from the fuzzed funder.
        DEFAULT_ASSET.approve({ spender: address(dynamic), amount: UINT256_MAX });

        // Expect the ERC-20 assets to be transferred from the funder to {SablierV2LockupDynamic}.
        expectTransferFromCall({
            from: funder,
            to: address(dynamic),
            amount: vars.createAmounts.deposit + vars.createAmounts.protocolFee
        });

        // Expect the broker fee to be paid to the broker, if not zero.
        if (vars.createAmounts.brokerFee > 0) {
            expectTransferFromCall({ from: funder, to: params.broker.account, amount: vars.createAmounts.brokerFee });
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
            asset: DEFAULT_ASSET,
            cancelable: params.cancelable,
            segments: params.segments,
            range: range,
            broker: params.broker.account
        });

        // Create the stream.
        dynamic.createWithMilestones(
            LockupDynamic.CreateWithMilestones({
                sender: params.sender,
                recipient: params.recipient,
                totalAmount: vars.totalAmount,
                asset: DEFAULT_ASSET,
                cancelable: params.cancelable,
                segments: params.segments,
                startTime: params.startTime,
                broker: params.broker
            })
        );

        // Assert that the stream has been created.
        LockupDynamic.Stream memory actualStream = dynamic.getStream(streamId);
        assertEq(actualStream.amounts, Lockup.Amounts({ deposit: vars.createAmounts.deposit, withdrawn: 0 }));
        assertEq(actualStream.asset, defaultStream.asset, "asset");
        assertEq(actualStream.endTime, range.end, "endTime");
        assertEq(actualStream.isCancelable, params.cancelable, "isCancelable");
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.segments, params.segments);
        assertEq(actualStream.startTime, range.start, "startTime");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = dynamic.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = dynamic.protocolRevenues(DEFAULT_ASSET);
        vars.expectedProtocolRevenues = vars.createAmounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = dynamic.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
