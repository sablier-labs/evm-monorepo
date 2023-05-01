// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { Errors } from "src/libraries/Errors.sol";

import { ISablierV2LockupDynamic } from "src/interfaces/ISablierV2LockupDynamic.sol";
import { Broker, Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract CreateWithMilestones_Dynamic_Unit_Test is Dynamic_Unit_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        super.setUp();
        streamId = dynamic.nextStreamId();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2LockupDynamic.createWithMilestones, defaultParams.createWithMilestones);
        (bool success, bytes memory returnData) = address(dynamic).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    function test_RevertWhen_RecipientZeroAddress() external whenNoDelegateCall {
        vm.expectRevert("ERC721: mint to the zero address");
        address recipient = address(0);
        createDefaultStreamWithRecipient(recipient);
    }

    modifier whenRecipientNonZeroAddress() {
        _;
    }

    function test_RevertWhen_DepositAmountZero() external whenNoDelegateCall whenRecipientNonZeroAddress {
        // It is not possible to obtain a zero deposit amount from a non-zero total amount, because the `MAX_FEE`
        // is hard coded to 10%.
        vm.expectRevert(Errors.SablierV2Lockup_DepositAmountZero.selector);
        uint128 totalAmount = 0;
        createDefaultStreamWithTotalAmount(totalAmount);
    }

    modifier whenDepositAmountNotZero() {
        _;
    }

    function test_RevertWhen_SegmentCountZero()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
    {
        LockupDynamic.Segment[] memory segments;
        vm.expectRevert(Errors.SablierV2LockupDynamic_SegmentCountZero.selector);
        createDefaultStreamWithSegments(segments);
    }

    modifier whenSegmentCountNotZero() {
        _;
    }

    function test_RevertWhen_SegmentCountTooHigh()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
    {
        uint256 segmentCount = DEFAULT_MAX_SEGMENT_COUNT + 1;
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](segmentCount);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2LockupDynamic_SegmentCountTooHigh.selector, segmentCount)
        );
        createDefaultStreamWithSegments(segments);
    }

    modifier whenSegmentCountNotTooHigh() {
        _;
    }

    function test_RevertWhen_SegmentAmountsSumOverflows()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
    {
        LockupDynamic.Segment[] memory segments = defaultParams.createWithMilestones.segments;
        segments[0].amount = UINT128_MAX;
        segments[1].amount = 1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStreamWithSegments(segments);
    }

    modifier whenSegmentAmountsSumDoesNotOverflow() {
        _;
    }

    function test_RevertWhen_StartTimeGreaterThanFirstSegmentMilestone()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
    {
        // Change the milestone of the first segment.
        LockupDynamic.Segment[] memory segments = defaultParams.createWithMilestones.segments;
        segments[0].milestone = DEFAULT_START_TIME - 1 seconds;

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

    function test_RevertWhen_StartTimeEqualToFirstSegmentMilestone()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
    {
        // Change the milestone of the first segment.
        LockupDynamic.Segment[] memory segments = defaultParams.createWithMilestones.segments;
        segments[0].milestone = DEFAULT_START_TIME;

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

    function test_RevertWhen_SegmentMilestonesNotOrdered()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
    {
        // Swap the segment milestones.
        LockupDynamic.Segment[] memory segments = defaultParams.createWithMilestones.segments;
        (segments[0].milestone, segments[1].milestone) = (segments[1].milestone, segments[0].milestone);

        // Expect a {SegmentMilestonesNotOrdered} error.
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupDynamic_SegmentMilestonesNotOrdered.selector,
                index,
                segments[0].milestone,
                segments[1].milestone
            )
        );

        // Create the stream.
        createDefaultStreamWithSegments(segments);
    }

    modifier whenSegmentMilestonesOrdered() {
        _;
    }

    function test_RevertWhen_EndTimeInThePast()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
    {
        vm.warp({ timestamp: DEFAULT_END_TIME });

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_EndTimeInThePast.selector, DEFAULT_END_TIME, DEFAULT_END_TIME)
        );
        createDefaultStream();
    }

    modifier whenEndTimeInTheFuture() {
        _;
    }

    function test_RevertWhen_DepositAmountNotEqualToSegmentAmountsSum()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
        whenEndTimeInTheFuture
    {
        // Disable both the protocol and the broker fee so that they don't interfere with the calculations.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        UD60x18 brokerFee = ZERO;
        changePrank(defaultParams.createWithMilestones.sender);

        // Adjust the default deposit amount.
        uint128 depositAmount = DEFAULT_DEPOSIT_AMOUNT + 100;

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

    function test_RevertWhen_ProtocolFeeTooHigh()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
        whenEndTimeInTheFuture
        whenStartTimeLessThanFirstSegmentMilestone
        whenDepositAmountEqualToSegmentAmountsSum
    {
        UD60x18 protocolFee = MAX_FEE.add(ud(1));

        // Set the protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee(defaultStream.asset, protocolFee);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_ProtocolFeeTooHigh.selector, protocolFee, MAX_FEE)
        );
        createDefaultStream();
    }

    modifier whenProtocolFeeNotTooHigh() {
        _;
    }

    function test_RevertWhen_BrokerFeeTooHigh()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
        whenEndTimeInTheFuture
        whenStartTimeLessThanFirstSegmentMilestone
        whenDepositAmountEqualToSegmentAmountsSum
        whenProtocolFeeNotTooHigh
    {
        UD60x18 brokerFee = MAX_FEE.add(ud(1));
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, brokerFee, MAX_FEE));
        createDefaultStreamWithBroker(Broker({ account: users.broker, fee: brokerFee }));
    }

    modifier whenBrokerFeeNotTooHigh() {
        _;
    }

    function test_RevertWhen_AssetNotContract()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
        whenEndTimeInTheFuture
        whenStartTimeLessThanFirstSegmentMilestone
        whenDepositAmountEqualToSegmentAmountsSum
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
    {
        address nonContract = address(8128);

        // Set the default protocol fee so that the test does not revert due to the deposit amount not being
        // equal to the sum of the segment amounts.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee(IERC20(nonContract), DEFAULT_PROTOCOL_FEE);
        changePrank({ msgSender: users.sender });

        // Run the test.
        vm.expectRevert("Address: call to non-contract");
        createDefaultStreamWithAsset(IERC20(nonContract));
    }

    modifier whenAssetContract() {
        _;
    }

    function test_CreateWithMilestones_AssetMissingReturnValue()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
        whenEndTimeInTheFuture
        whenStartTimeLessThanFirstSegmentMilestone
        whenDepositAmountEqualToSegmentAmountsSum
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
        whenAssetContract
    {
        testCreateWithMilestones(address(nonCompliantAsset));
    }

    modifier whenAssetERC20Compliant() {
        _;
    }

    function test_CreateWithMilestones()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
        whenEndTimeInTheFuture
        whenStartTimeLessThanFirstSegmentMilestone
        whenDepositAmountEqualToSegmentAmountsSum
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
        whenAssetContract
        whenAssetERC20Compliant
    {
        testCreateWithMilestones(address(DEFAULT_ASSET));
    }

    /// @dev Test logic shared between {test_CreateWithMilestones_AssetMissingReturnValue} and
    /// {test_CreateWithMilestones}.
    function testCreateWithMilestones(address asset) internal {
        // Make the sender the stream's funder.
        address funder = users.sender;

        // Expect the assets to be transferred from the funder to {SablierV2LockupDynamic}.
        expectCallToTransferFrom({
            asset: IERC20(asset),
            from: funder,
            to: address(dynamic),
            amount: DEFAULT_DEPOSIT_AMOUNT + DEFAULT_PROTOCOL_FEE_AMOUNT
        });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({
            asset: IERC20(asset),
            from: funder,
            to: users.broker,
            amount: DEFAULT_BROKER_FEE_AMOUNT
        });

        // Expect a {CreateLockupDynamicStream} event to be emitted.
        vm.expectEmit({ emitter: address(dynamic) });
        emit CreateLockupDynamicStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: DEFAULT_LOCKUP_CREATE_AMOUNTS,
            segments: DEFAULT_SEGMENTS,
            asset: IERC20(asset),
            cancelable: true,
            range: DEFAULT_DYNAMIC_RANGE,
            broker: users.broker
        });

        // Create the stream.
        streamId = createDefaultStreamWithAsset(IERC20(asset));

        // Assert that the stream has been created.
        LockupDynamic.Stream memory actualStream = dynamic.getStream(streamId);
        LockupDynamic.Stream memory expectedStream = defaultStream;
        expectedStream.asset = IERC20(asset);
        assertEq(actualStream, expectedStream);

        // Assert that the stream's status is "STREAMING".
        Lockup.Status actualStatus = dynamic.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = dynamic.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the NFT has been minted.
        address actualNFTOwner = dynamic.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultParams.createWithMilestones.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
