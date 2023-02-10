// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Broker, Lockup, LockupPro } from "src/types/DataTypes.sol";

import { ISablierV2LockupPro } from "src/interfaces/ISablierV2LockupPro.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract CreateWithMilestones_Pro_Unit_Test is Pro_Unit_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        super.setUp();
        streamId = pro.nextStreamId();
    }

    /// @dev it should revert.
    function test_RevertWhen_RecipientZeroAddress() external {
        vm.expectRevert("ERC721: mint to the zero address");
        address recipient = address(0);
        createDefaultStreamWithRecipient(recipient);
    }

    modifier recipientNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    ///
    /// It is not possible (in principle) to obtain a zero deposit amount from a non-zero total amount,
    /// because we hard-code the `MAX_FEE` to 10%.
    function test_RevertWhen_DepositAmountZero() external recipientNonZeroAddress {
        vm.expectRevert(Errors.SablierV2Lockup_DepositAmountZero.selector);
        uint128 totalAmount = 0;
        createDefaultStreamWithTotalAmount(totalAmount);
    }

    modifier depositAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_SegmentCountZero() external recipientNonZeroAddress depositAmountNotZero {
        LockupPro.Segment[] memory segments;
        vm.expectRevert(Errors.SablierV2LockupPro_SegmentCountZero.selector);
        createDefaultStreamWithSegments(segments);
    }

    modifier segmentCountNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_SegmentCountTooHigh()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
    {
        uint256 segmentCount = DEFAULT_MAX_SEGMENT_COUNT + 1;
        LockupPro.Segment[] memory segments = new LockupPro.Segment[](segmentCount);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2LockupPro_SegmentCountTooHigh.selector, segmentCount));
        createDefaultStreamWithSegments(segments);
    }

    modifier segmentCountNotTooHigh() {
        _;
    }

    /// @dev When the segment amounts sum overflows, it should revert.
    function test_RevertWhen_SegmentAmountsSumOverflows()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
    {
        LockupPro.Segment[] memory segments = defaultParams.createWithMilestones.segments;
        segments[0].amount = UINT128_MAX;
        segments[1].amount = 1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStreamWithSegments(segments);
    }

    modifier segmentAmountsSumDoesNotOverflow() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_StartTimeGreaterThanFirstSegmentMilestone()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
    {
        // Change the milestone of the first segment.
        LockupPro.Segment[] memory segments = defaultParams.createWithMilestones.segments;
        segments[0].milestone = DEFAULT_START_TIME - 1;

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

    /// @dev it should revert.
    function test_RevertWhen_StartTimeEqualToFirstSegmentMilestone()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
    {
        // Change the milestone of the first segment.
        LockupPro.Segment[] memory segments = defaultParams.createWithMilestones.segments;
        segments[0].milestone = DEFAULT_START_TIME;

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

    /// @dev it should revert.
    function test_RevertWhen_SegmentMilestonesNotOrdered()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        startTimeLessThanFirstSegmentMilestone
    {
        // Swap the segment milestones.
        LockupPro.Segment[] memory segments = defaultParams.createWithMilestones.segments;
        (segments[0].milestone, segments[1].milestone) = (segments[1].milestone, segments[0].milestone);

        // Expect a {SegmentMilestonesNotOrdered} error.
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupPro_SegmentMilestonesNotOrdered.selector,
                index,
                segments[0].milestone,
                segments[1].milestone
            )
        );

        // Create the stream.
        createDefaultStreamWithSegments(segments);
    }

    modifier segmentMilestonesOrdered() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_DepositAmountNotEqualToSegmentAmountsSum()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        startTimeLessThanFirstSegmentMilestone
        segmentMilestonesOrdered
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
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.startTime,
            Broker({ account: address(0), fee: brokerFee })
        );
    }

    modifier depositAmountEqualToSegmentAmountsSum() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ProtocolFeeTooHigh()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        startTimeLessThanFirstSegmentMilestone
        segmentMilestonesOrdered
        startTimeLessThanFirstSegmentMilestone
        depositAmountEqualToSegmentAmountsSum
    {
        UD60x18 protocolFee = DEFAULT_MAX_FEE.add(ud(1));

        // Set the protocol fee.
        changePrank({ msgSender: users.admin });
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
    function test_RevertWhen_BrokerFeeTooHigh()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        startTimeLessThanFirstSegmentMilestone
        segmentMilestonesOrdered
        startTimeLessThanFirstSegmentMilestone
        depositAmountEqualToSegmentAmountsSum
        protocolFeeNotTooHigh
    {
        UD60x18 brokerFee = DEFAULT_MAX_FEE.add(ud(1));
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, brokerFee, DEFAULT_MAX_FEE)
        );
        pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.totalAmount,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.startTime,
            Broker({ account: users.broker, fee: brokerFee })
        );
    }

    modifier brokerFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_AssetNotContract()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        startTimeLessThanFirstSegmentMilestone
        segmentMilestonesOrdered
        startTimeLessThanFirstSegmentMilestone
        depositAmountEqualToSegmentAmountsSum
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
    {
        address nonContract = address(8128);

        // Set the default protocol fee so that the test does not revert due to the deposit amount not being
        // equal to the segment amounts sum.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee(IERC20(nonContract), DEFAULT_PROTOCOL_FEE);
        changePrank({ msgSender: users.sender });

        // Run the test.
        vm.expectRevert("Address: call to non-contract");
        pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.totalAmount,
            IERC20(nonContract),
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    modifier assetContract() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, and mint the NFT.
    function test_CreateWithMilestones_AssetMissingReturnValue()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        startTimeLessThanFirstSegmentMilestone
        segmentMilestonesOrdered
        startTimeLessThanFirstSegmentMilestone
        depositAmountEqualToSegmentAmountsSum
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
        assetContract
    {
        test_createWithMilestones(address(nonCompliantAsset));
    }

    modifier assetERC20Compliant() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, record the protocol
    /// fee, mint the NFT, and emit a {CreateLockupProStream} event.
    function test_CreateWithMilestones()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        startTimeLessThanFirstSegmentMilestone
        segmentMilestonesOrdered
        startTimeLessThanFirstSegmentMilestone
        depositAmountEqualToSegmentAmountsSum
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
        assetContract
        assetERC20Compliant
    {
        test_createWithMilestones(address(DEFAULT_ASSET));
    }

    /// @dev Shared test logic for `test_CreateWithMilestones_AssetMissingReturnValue` and `test_CreateWithMilestones`.
    function test_createWithMilestones(address asset) internal {
        // Make the sender the funder of the stream.
        address funder = users.sender;

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupPro} contract.
        expectTransferFromCall({
            asset: IERC20(asset),
            from: funder,
            to: address(pro),
            amount: DEFAULT_DEPOSIT_AMOUNT + DEFAULT_PROTOCOL_FEE_AMOUNT
        });

        // Expect the broker fee to be paid to the broker.
        expectTransferFromCall({
            asset: IERC20(asset),
            from: funder,
            to: users.broker,
            amount: DEFAULT_BROKER_FEE_AMOUNT
        });

        // Expect a {CreateLockupProStream} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLockupProStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: DEFAULT_LOCKUP_CREATE_AMOUNTS,
            segments: DEFAULT_SEGMENTS,
            asset: IERC20(asset),
            cancelable: true,
            range: DEFAULT_PRO_RANGE,
            broker: users.broker
        });

        // Create the stream.
        pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.totalAmount,
            IERC20(asset),
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );

        // Assert that the stream has been created.
        LockupPro.Stream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(address(actualStream.asset), asset, "asset");
        assertEq(actualStream.isCancelable, defaultStream.isCancelable, "isCancelable");
        assertEq(actualStream.endTime, defaultStream.endTime, "endTime");
        assertEq(actualStream.sender, defaultStream.sender, "sender");
        assertEq(actualStream.segments, defaultStream.segments);
        assertEq(actualStream.startTime, defaultStream.startTime, "startTime");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the NFT has been minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultParams.createWithMilestones.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
