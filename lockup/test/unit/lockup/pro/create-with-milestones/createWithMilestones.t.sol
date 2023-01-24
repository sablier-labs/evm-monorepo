// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Broker, CreateLockupAmounts, LockupAmounts, LockupProStream, Segment } from "src/types/Structs.sol";

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
    /// It is not possible (in principle) to obtain a zero net deposit amount from a non-zero gross deposit amount,
    /// because we hard-code the `MAX_FEE` to 10%.
    function test_RevertWhen_NetDepositAmountZero() external recipientNonZeroAddress {
        vm.expectRevert(Errors.SablierV2Lockup_NetDepositAmountZero.selector);
        uint128 grossDepositAmount = 0;
        createDefaultStreamWithGrossDepositAmount(grossDepositAmount);
    }

    modifier netDepositAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_SegmentCountZero() external recipientNonZeroAddress netDepositAmountNotZero {
        Segment[] memory segments;
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
        netDepositAmountNotZero
        segmentCountNotZero
    {
        uint256 segmentCount = DEFAULT_MAX_SEGMENT_COUNT + 1;
        Segment[] memory segments = new Segment[](segmentCount);
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
        netDepositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
    {
        Segment[] memory segments = defaultParams.createWithMilestones.segments;
        segments[0].amount = UINT128_MAX;
        segments[1].amount = 1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStreamWithSegments(segments);
    }

    modifier segmentAmountsSumDoesNotOverflow() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_SegmentMilestonesNotOrdered()
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
    {
        // Swap the segment milestones.
        Segment[] memory segments = defaultParams.createWithMilestones.segments;
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
    function test_RevertWhen_NetDepositAmountNotEqualToSegmentAmountsSum()
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
    {
        // Disable both the protocol and the broker fee so that they don't interfere with the calculations.
        changePrank({ who: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        UD60x18 brokerFee = ZERO;
        changePrank(defaultParams.createWithMilestones.sender);

        // Adjust the default net deposit amount.
        uint128 netDepositAmount = DEFAULT_NET_DEPOSIT_AMOUNT + 100;

        // Expect a {NetDepositAmountNotEqualToSegmentAmountsSum} error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupPro_NetDepositAmountNotEqualToSegmentAmountsSum.selector,
                netDepositAmount,
                DEFAULT_NET_DEPOSIT_AMOUNT
            )
        );

        // Create the stream.
        pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            netDepositAmount,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: brokerFee })
        );
    }

    modifier netDepositAmountEqualToSegmentAmountsSum() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ProtocolFeeTooHigh()
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
        netDepositAmountEqualToSegmentAmountsSum
    {
        UD60x18 protocolFee = DEFAULT_MAX_FEE.add(ud(1));

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
    function test_RevertWhen_BrokerFeeTooHigh()
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
        netDepositAmountEqualToSegmentAmountsSum
        protocolFeeNotTooHigh
    {
        UD60x18 brokerFee = DEFAULT_MAX_FEE.add(ud(1));
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, brokerFee, DEFAULT_MAX_FEE)
        );
        pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.grossDepositAmount,
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

    /// @dev it should revert.
    function test_RevertWhen_AssetNotContract()
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
        netDepositAmountEqualToSegmentAmountsSum
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
    {
        address nonContract = address(8128);

        // Set the default protocol fee so that the test does not revert due to the net deposit amount not being
        // equal to the segment amounts sum.
        changePrank({ who: users.admin });
        comptroller.setProtocolFee(IERC20(nonContract), DEFAULT_PROTOCOL_FEE);
        changePrank({ who: users.sender });

        // Run the test.
        vm.expectRevert("Address: call to non-contract");
        pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.grossDepositAmount,
            defaultParams.createWithMilestones.segments,
            IERC20(nonContract),
            defaultParams.createWithMilestones.cancelable,
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
        netDepositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
        netDepositAmountEqualToSegmentAmountsSum
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
        netDepositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
        netDepositAmountEqualToSegmentAmountsSum
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
        assetContract
        assetERC20Compliant
    {
        test_createWithMilestones(address(DEFAULT_ASSET));
    }

    /// @dev Shared test logic for `test_CreateWithMilestones_AssetMissingReturnValue` and `test_CreateWithMilestones`.
    function test_createWithMilestones(address asset) internal {
        // Make the sender the funder in this test.
        address funder = defaultParams.createWithMilestones.sender;

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupPro} contract.
        vm.expectCall(
            asset,
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, address(pro), DEFAULT_NET_DEPOSIT_AMOUNT + DEFAULT_PROTOCOL_FEE_AMOUNT)
            )
        );

        // Expect the broker fee to be paid to the broker.
        vm.expectCall(
            asset,
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, defaultParams.createWithMilestones.broker.addr, DEFAULT_BROKER_FEE_AMOUNT)
            )
        );

        // Create the stream.
        pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.grossDepositAmount,
            defaultParams.createWithMilestones.segments,
            IERC20(asset),
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );

        // Assert that the stream was created.
        LockupProStream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(address(actualStream.asset), asset, "asset");
        assertEq(actualStream.isCancelable, defaultStream.isCancelable, "isCancelable");
        assertEq(actualStream.sender, defaultStream.sender, "sender");
        assertEq(actualStream.segments, defaultStream.segments);
        assertEq(actualStream.startTime, defaultStream.startTime, "startTime");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the NFT was minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultParams.createWithMilestones.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
