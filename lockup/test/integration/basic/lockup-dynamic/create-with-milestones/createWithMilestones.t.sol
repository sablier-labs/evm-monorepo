// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { Errors } from "src/libraries/Errors.sol";

import { ISablierV2LockupDynamic } from "src/interfaces/ISablierV2LockupDynamic.sol";
import { Broker, Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { CreateWithMilestones_Integration_Shared_Test } from
    "../../../shared/lockup-dynamic/create-with-milestones/createWithMilestones.t.sol";
import { Dynamic_Integration_Basic_Test } from "../Dynamic.t.sol";

contract CreateWithMilestones_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    CreateWithMilestones_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(Dynamic_Integration_Basic_Test, CreateWithMilestones_Integration_Shared_Test)
    {
        Dynamic_Integration_Basic_Test.setUp();
        CreateWithMilestones_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCalled() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2LockupDynamic.createWithMilestones, defaults.createWithMilestones());
        (bool success, bytes memory returnData) = address(dynamic).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_RecipientZeroAddress() external whenNotDelegateCalled {
        vm.expectRevert("ERC721: mint to the zero address");
        address recipient = address(0);
        createDefaultStreamWithRecipient(recipient);
    }

    function test_RevertWhen_DepositAmountZero() external whenNotDelegateCalled whenRecipientNonZeroAddress {
        // It is not possible to obtain a zero deposit amount from a non-zero total amount, because the `MAX_FEE`
        // is hard coded to 10%.
        vm.expectRevert(Errors.SablierV2Lockup_DepositAmountZero.selector);
        uint128 totalAmount = 0;
        createDefaultStreamWithTotalAmount(totalAmount);
    }

    function test_RevertWhen_SegmentCountZero()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
    {
        LockupDynamic.Segment[] memory segments;
        vm.expectRevert(Errors.SablierV2LockupDynamic_SegmentCountZero.selector);
        createDefaultStreamWithSegments(segments);
    }

    function test_RevertWhen_SegmentCountTooHigh()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
    {
        uint256 segmentCount = defaults.MAX_SEGMENT_COUNT() + 1;
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](segmentCount);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2LockupDynamic_SegmentCountTooHigh.selector, segmentCount)
        );
        createDefaultStreamWithSegments(segments);
    }

    function test_RevertWhen_SegmentAmountsSumOverflows()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
    {
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].amount = MAX_UINT128;
        segments[1].amount = 1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStreamWithSegments(segments);
    }

    function test_RevertWhen_StartTimeGreaterThanFirstSegmentMilestone()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
    {
        // Change the milestone of the first segment.
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].milestone = defaults.START_TIME() - 1 seconds;

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

    function test_RevertWhen_StartTimeEqualToFirstSegmentMilestone()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
    {
        // Change the milestone of the first segment.
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].milestone = defaults.START_TIME();

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

    function test_RevertWhen_SegmentMilestonesNotOrdered()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
    {
        // Swap the segment milestones.
        LockupDynamic.Segment[] memory segments = defaults.segments();
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

    function test_RevertWhen_EndTimeNotInTheFuture()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
    {
        uint40 endTime = defaults.END_TIME();
        vm.warp({ timestamp: endTime });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_EndTimeNotInTheFuture.selector, endTime, endTime));
        createDefaultStream();
    }

    function test_RevertWhen_DepositAmountNotEqualToSegmentAmountsSum()
        external
        whenNotDelegateCalled
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
        comptroller.setProtocolFee({ asset: dai, newProtocolFee: ZERO });
        UD60x18 brokerFee = ZERO;
        changePrank({ msgSender: users.sender });

        // Adjust the default deposit amount.
        uint128 defaultDepositAmount = defaults.DEPOSIT_AMOUNT();
        uint128 depositAmount = defaultDepositAmount + 100;

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

    function test_RevertWhen_ProtocolFeeTooHigh()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
        whenEndTimeInTheFuture
        whenDepositAmountEqualToSegmentAmountsSum
    {
        UD60x18 protocolFee = MAX_FEE + ud(1);

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

    function test_RevertWhen_BrokerFeeTooHigh()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
        whenEndTimeInTheFuture
        whenDepositAmountEqualToSegmentAmountsSum
        whenProtocolFeeNotTooHigh
    {
        UD60x18 brokerFee = MAX_FEE + ud(1);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, brokerFee, MAX_FEE));
        createDefaultStreamWithBroker(Broker({ account: users.broker, fee: brokerFee }));
    }

    function test_RevertWhen_AssetNotContract()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
        whenEndTimeInTheFuture
        whenDepositAmountEqualToSegmentAmountsSum
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
    {
        address nonContract = address(8128);

        // Set the default protocol fee so that the test does not revert due to the deposit amount not being
        // equal to the sum of the segment amounts.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee(IERC20(nonContract), defaults.PROTOCOL_FEE());
        changePrank({ msgSender: users.sender });

        // Run the test.
        vm.expectRevert("Address: call to non-contract");
        createDefaultStreamWithAsset(IERC20(nonContract));
    }

    function test_CreateWithMilestones_AssetMissingReturnValue()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
        whenEndTimeInTheFuture
        whenDepositAmountEqualToSegmentAmountsSum
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
        whenAssetContract
    {
        testCreateWithMilestones(address(usdt));
    }

    function test_CreateWithMilestones()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotTooHigh
        whenSegmentAmountsSumDoesNotOverflow
        whenStartTimeLessThanFirstSegmentMilestone
        whenSegmentMilestonesOrdered
        whenEndTimeInTheFuture
        whenDepositAmountEqualToSegmentAmountsSum
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
        whenAssetContract
        whenAssetERC20
    {
        testCreateWithMilestones(address(dai));
    }

    /// @dev Shared logic between {test_CreateWithMilestones_AssetMissingReturnValue} and {test_CreateWithMilestones}.
    function testCreateWithMilestones(address asset) internal {
        // Make the Sender the stream's funder.
        address funder = users.sender;

        // Expect the assets to be transferred from the funder to {SablierV2LockupDynamic}.
        expectCallToTransferFrom({
            asset: IERC20(asset),
            from: funder,
            to: address(dynamic),
            amount: defaults.DEPOSIT_AMOUNT() + defaults.PROTOCOL_FEE_AMOUNT()
        });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({
            asset: IERC20(asset),
            from: funder,
            to: users.broker,
            amount: defaults.BROKER_FEE_AMOUNT()
        });

        // Expect a {CreateLockupDynamicStream} event to be emitted.
        vm.expectEmit({ emitter: address(dynamic) });
        emit CreateLockupDynamicStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            segments: defaults.segments(),
            asset: IERC20(asset),
            cancelable: true,
            range: defaults.dynamicRange(),
            broker: users.broker
        });

        // Create the stream.
        streamId = createDefaultStreamWithAsset(IERC20(asset));

        // Assert that the stream has been created.
        LockupDynamic.Stream memory actualStream = dynamic.getStream(streamId);
        LockupDynamic.Stream memory expectedStream = defaults.dynamicStream();
        expectedStream.asset = IERC20(asset);
        assertEq(actualStream, expectedStream);

        // Assert that the stream's status is "PENDING".
        Lockup.Status actualStatus = dynamic.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.PENDING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = dynamic.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the NFT has been minted.
        address actualNFTOwner = dynamic.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
