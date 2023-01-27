// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { ISablierV2LockupPro } from "src/interfaces/ISablierV2LockupPro.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Broker, Lockup, LockupPro } from "src/types/DataTypes.sol";

import { Pro_Fuzz_Test } from "../Pro.t.sol";

contract CreateWithMilestones_Pro_Fuzz_Test is Pro_Fuzz_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        super.setUp();

        // Load the stream id.
        streamId = pro.nextStreamId();
    }

    modifier recipientNonZeroAddress() {
        _;
    }

    modifier depositAmountNotZero() {
        _;
    }

    modifier segmentCountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_SegmentCountTooHigh(
        uint256 segmentCount
    ) external recipientNonZeroAddress depositAmountNotZero segmentCountNotZero {
        segmentCount = bound(segmentCount, DEFAULT_MAX_SEGMENT_COUNT + 1, DEFAULT_MAX_SEGMENT_COUNT * 10);
        LockupPro.Segment[] memory segments = new LockupPro.Segment[](segmentCount);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2LockupPro_SegmentCountTooHigh.selector, segmentCount));
        createDefaultStreamWithSegments(segments);
    }

    modifier segmentCountNotTooHigh() {
        _;
    }

    /// @dev When the segment amounts sum overflows, it should revert.
    function testFuzz_RevertWhen_SegmentAmountsSumOverflows(
        uint128 amount0,
        uint128 amount1
    ) external recipientNonZeroAddress depositAmountNotZero segmentCountNotZero segmentCountNotTooHigh {
        amount0 = boundUint128(amount0, UINT128_MAX / 2 + 1, UINT128_MAX);
        amount1 = boundUint128(amount0, UINT128_MAX / 2 + 1, UINT128_MAX);
        LockupPro.Segment[] memory segments = DEFAULT_SEGMENTS;
        segments[0].amount = amount0;
        segments[1].amount = amount1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStreamWithSegments(segments);
    }

    modifier segmentAmountsSumDoesNotOverflow() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_StartTimeNotLessThanFirstSegmentMilestone(
        uint40 firstMilestone
    )
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
    {
        firstMilestone = boundUint40(firstMilestone, 0, DEFAULT_START_TIME);

        // Change the milestone of the first segment.
        LockupPro.Segment[] memory segments = DEFAULT_SEGMENTS;
        segments[0].milestone = firstMilestone;

        // Expect a {StartTimeNotLessThanFirstSegmentMilestone} error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupPro_StartTimeNotLessThanFirstSegmentMilestone.selector,
                DEFAULT_START_TIME,
                segments[0].milestone
            )
        );

        // Create the stream.
        createDefaultStreamWithSegments(segments);
    }

    modifier startTimeLessThanFirstSegmentMilestone() {
        _;
    }

    modifier segmentMilestonesOrdered() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_DepositAmountNotEqualToSegmentAmountsSum(
        uint128 depositDiff
    )
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
        startTimeLessThanFirstSegmentMilestone
    {
        depositDiff = boundUint128(depositDiff, 100, DEFAULT_TOTAL_AMOUNT);

        // Disable both the protocol and the broker fee so that they don't interfere with the calculations.
        changePrank({ who: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        UD60x18 brokerFee = ZERO;
        changePrank(defaultParams.createWithMilestones.sender);

        // Adjust the default deposit amount.
        uint128 depositAmount = DEFAULT_DEPOSIT_AMOUNT + depositDiff;

        // Expect a {DepositAmountNotEqualToSegmentAmountsSum} error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupPro_DepositAmountNotEqualToSegmentAmountsSum.selector,
                depositAmount,
                DEFAULT_DEPOSIT_AMOUNT
            )
        );

        // Create the stream.
        pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            depositAmount,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: brokerFee })
        );
    }

    modifier depositAmountEqualToSegmentAmountsSum() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_ProtocolFeeTooHigh(
        UD60x18 protocolFee
    )
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
        startTimeLessThanFirstSegmentMilestone
        depositAmountEqualToSegmentAmountsSum
    {
        protocolFee = bound(protocolFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);

        // Set the protocol fee.
        changePrank({ who: users.admin });
        comptroller.setProtocolFee(defaultStream.asset, protocolFee);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_ProtocolFeeTooHigh.selector, protocolFee, DEFAULT_MAX_FEE)
        );
        createDefaultStream();
    }

    modifier protocolFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_BrokerFeeTooHigh(
        UD60x18 brokerFee
    )
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
        startTimeLessThanFirstSegmentMilestone
        depositAmountEqualToSegmentAmountsSum
        protocolFeeNotTooHigh
    {
        brokerFee = bound(brokerFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, brokerFee, DEFAULT_MAX_FEE)
        );
        pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.totalAmount,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            Broker({ addr: users.broker, fee: brokerFee })
        );
    }

    modifier brokerFeeNotTooHigh() {
        _;
    }

    modifier assetContract() {
        _;
    }

    modifier assetERC20Compliant() {
        _;
    }

    struct Params {
        Broker broker;
        bool cancelable;
        address funder;
        UD60x18 protocolFee;
        address recipient;
        address sender;
        uint40 startTime;
        uint128 totalAmount;
    }

    struct Vars {
        uint256 actualNextStreamId;
        address actualNFTOwner;
        uint256 actualProtocolRevenues;
        uint128 brokerFeeAmount;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        uint256 expectedProtocolRevenues;
        uint128 initialProtocolRevenues;
        uint128 depositAmount;
        uint128 protocolFeeAmount;
        LockupPro.Segment[] segments;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, record the protocol
    /// fee, mint the NFT, and emit a {CreateLockupProStream} event.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, sender, recipient, and broker.
    /// - Multiple values for the total amount.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time equal and not equal to the first segment milestone.
    /// - Multiple values for the broker fee, including zero.
    /// - Multiple values for the protocol fee, including zero.
    function testFuzz_CreateWithMilestones(
        Params memory params
    )
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
        startTimeLessThanFirstSegmentMilestone
        depositAmountEqualToSegmentAmountsSum
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
        assetContract
        assetERC20Compliant
    {
        vm.assume(params.funder != address(0) && params.recipient != address(0) && params.broker.addr != address(0));
        vm.assume(params.totalAmount != 0);
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        params.protocolFee = bound(params.protocolFee, 0, DEFAULT_MAX_FEE);
        params.startTime = boundUint40(
            params.startTime,
            0,
            defaultParams.createWithMilestones.segments[0].milestone - 1
        );

        // Set the fuzzed protocol fee.
        changePrank({ who: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: params.protocolFee });

        // Make the fuzzed funder the caller in this test.
        changePrank(params.funder);

        // Mint enough ERC-20 assets to the fuzzed funder.
        deal({ token: address(DEFAULT_ASSET), to: params.funder, give: params.totalAmount });

        // Approve the {SablierV2LockupPro} contract to transfer the assets from the funder.
        DEFAULT_ASSET.approve({ spender: address(pro), amount: UINT256_MAX });

        // Load the initial protocol revenues.
        Vars memory vars;
        vars.initialProtocolRevenues = pro.getProtocolRevenues(DEFAULT_ASSET);

        // Calculate the broker fee amount and the deposit amount.
        vars.protocolFeeAmount = ud(params.totalAmount).mul(params.protocolFee).intoUint128();
        vars.brokerFeeAmount = ud(params.totalAmount).mul(params.broker.fee).intoUint128();
        vars.depositAmount = params.totalAmount - vars.protocolFeeAmount - vars.brokerFeeAmount;

        // Adjust the segment amounts based on the fuzzed deposit amount.
        vars.segments = defaultParams.createWithMilestones.segments;
        adjustSegmentAmounts(vars.segments, vars.depositAmount);

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupPro} contract.
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(
                IERC20.transferFrom,
                (params.funder, address(pro), vars.depositAmount + vars.protocolFeeAmount)
            )
        );

        // Expect the broker fee to be paid to the broker, if the fee amount is not zero.
        if (vars.brokerFeeAmount > 0) {
            vm.expectCall(
                address(DEFAULT_ASSET),
                abi.encodeCall(IERC20.transferFrom, (params.funder, params.broker.addr, vars.brokerFeeAmount))
            );
        }

        // Expect a {CreateLockupProStream} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLockupProStream({
            streamId: streamId,
            funder: params.funder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: Lockup.CreateAmounts({
                deposit: vars.depositAmount,
                protocolFee: vars.protocolFeeAmount,
                brokerFee: vars.brokerFeeAmount
            }),
            segments: vars.segments,
            asset: DEFAULT_ASSET,
            cancelable: params.cancelable,
            range: LockupPro.Range({ start: params.startTime, end: DEFAULT_END_TIME }),
            broker: params.broker.addr
        });

        // Create the stream.
        pro.createWithMilestones(
            params.sender,
            params.recipient,
            params.totalAmount,
            vars.segments,
            DEFAULT_ASSET,
            params.cancelable,
            params.startTime,
            params.broker
        );

        // Assert that the stream was created.
        LockupPro.Stream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, Lockup.Amounts({ deposit: vars.depositAmount, withdrawn: 0 }));
        assertEq(actualStream.asset, defaultStream.asset, "asset");
        assertEq(actualStream.isCancelable, params.cancelable, "isCancelable");
        assertEq(actualStream.range, LockupPro.Range({ start: params.startTime, end: defaultStream.range.end }));
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.segments, vars.segments);
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id was bumped.
        vars.actualNextStreamId = pro.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee was recorded.
        vars.actualProtocolRevenues = pro.getProtocolRevenues(DEFAULT_ASSET);
        vars.expectedProtocolRevenues = vars.initialProtocolRevenues + vars.protocolFeeAmount;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT was minted.
        vars.actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
