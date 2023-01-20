// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20_CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { MAX_UD60x18, UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { LockupAmounts, Broker, LockupProStream, Segment } from "src/types/Structs.sol";

import { ISablierV2LockupPro } from "src/interfaces/ISablierV2LockupPro.sol";

import { Pro_Test } from "../Pro.t.sol";

contract CreateWithMilestones_Pro_Test is Pro_Test {
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
    function testFuzz_RevertWhen_SegmentCountTooHigh(
        uint256 segmentCount
    ) external recipientNonZeroAddress netDepositAmountNotZero segmentCountNotZero {
        segmentCount = bound(segmentCount, DEFAULT_MAX_SEGMENT_COUNT + 1, DEFAULT_MAX_SEGMENT_COUNT * 10);
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
        Segment[] memory segments = params.createWithMilestones.segments;
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
        Segment[] memory segments = params.createWithMilestones.segments;
        (segments[0].milestone, segments[1].milestone) = (segments[1].milestone, segments[0].milestone);

        // Expect an error.
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
    function testFuzz_RevertWhen_NetDepositAmountNotEqualToSegmentAmountsSum(
        uint128 depositDelta
    )
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
    {
        depositDelta = boundUint128(depositDelta, 100, DEFAULT_GROSS_DEPOSIT_AMOUNT);

        // Disable both the protocol and the broker fee so that they don't interfere with the calculations.
        changePrank(users.admin);
        comptroller.setProtocolFee(params.createWithMilestones.asset, ZERO);
        UD60x18 brokerFee = ZERO;
        changePrank(params.createWithMilestones.sender);

        // Adjust the default net deposit amount.
        uint128 netDepositAmount = DEFAULT_NET_DEPOSIT_AMOUNT + depositDelta;

        // Expect an error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupPro_NetDepositAmountNotEqualToSegmentAmountsSum.selector,
                netDepositAmount,
                DEFAULT_NET_DEPOSIT_AMOUNT
            )
        );

        // Create the stream.
        pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            netDepositAmount,
            params.createWithMilestones.segments,
            params.createWithMilestones.asset,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: brokerFee })
        );
    }

    modifier netDepositAmountEqualToSegmentAmountsSum() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_ProtocolFeeTooHigh(
        UD60x18 protocolFee
    )
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
        netDepositAmountEqualToSegmentAmountsSum
    {
        protocolFee = bound(protocolFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);

        // Set the protocol fee.
        changePrank(users.admin);
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
        netDepositAmountNotZero
        segmentCountNotZero
        segmentCountNotTooHigh
        segmentAmountsSumDoesNotOverflow
        segmentMilestonesOrdered
        netDepositAmountEqualToSegmentAmountsSum
        protocolFeeNotTooHigh
    {
        brokerFee = bound(brokerFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, brokerFee, DEFAULT_MAX_FEE)
        );
        pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            params.createWithMilestones.grossDepositAmount,
            params.createWithMilestones.segments,
            params.createWithMilestones.asset,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            Broker({ addr: users.broker, fee: brokerFee })
        );
    }

    modifier brokerFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_AssetNotContract(
        IERC20 nonContract
    )
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
        vm.assume(address(nonContract).code.length == 0);

        // Set the default protocol fee so that the test does not revert due to the net deposit amount not being
        // equal to the segment amounts sum.
        changePrank(users.admin);
        comptroller.setProtocolFee(nonContract, DEFAULT_PROTOCOL_FEE);
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(SafeERC20_CallToNonContract.selector, address(nonContract)));
        pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            params.createWithMilestones.grossDepositAmount,
            params.createWithMilestones.segments,
            nonContract,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            params.createWithMilestones.broker
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
        // Load the stream id.
        uint256 streamId = pro.nextStreamId();

        // Make the sender the funder in this test.
        address funder = params.createWithMilestones.sender;

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupPro} contract.
        vm.expectCall(
            address(nonCompliantAsset),
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, address(pro), DEFAULT_NET_DEPOSIT_AMOUNT + DEFAULT_PROTOCOL_FEE_AMOUNT)
            )
        );

        // Expect the broker fee to be paid to the broker.
        vm.expectCall(
            address(nonCompliantAsset),
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, params.createWithMilestones.broker.addr, DEFAULT_BROKER_FEE_AMOUNT)
            )
        );

        // Create the stream.
        pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            params.createWithMilestones.grossDepositAmount,
            params.createWithMilestones.segments,
            IERC20(address(nonCompliantAsset)),
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            params.createWithMilestones.broker
        );

        // Assert that the stream was created.
        LockupProStream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(actualStream.isCancelable, defaultStream.isCancelable);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.segments, defaultStream.segments);
        assertEq(actualStream.startTime, defaultStream.startTime);
        assertEq(actualStream.status, defaultStream.status);
        assertEq(actualStream.asset, IERC20(address(nonCompliantAsset)));

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = params.createWithMilestones.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }

    modifier assetERC20Compliant() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, emit a CreateLockupProStream event, create the stream, record the
    /// protocol fee, bump the next stream id, and mint the NFT.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, recipient, sender, and broker.
    /// - Multiple values for the gross deposit amount.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time equal and not equal to the first segment milestone.
    /// - Multiple values for the broker fee, including zero.
    function testFuzz_CreateWithMilestones(
        address funder,
        address recipient,
        uint128 grossDepositAmount,
        bool cancelable,
        uint40 startTime,
        Broker memory broker
    )
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
        vm.assume(funder != address(0) && recipient != address(0) && broker.addr != address(0));
        vm.assume(grossDepositAmount != 0);
        broker.fee = bound(broker.fee, 0, DEFAULT_MAX_FEE);
        startTime = boundUint40(startTime, 0, params.createWithMilestones.segments[0].milestone);

        // Make the fuzzed funder the caller in this test.
        changePrank(funder);

        // Mint enough assets to the funder.
        deal({ token: address(params.createWithMilestones.asset), to: funder, give: grossDepositAmount });

        // Approve the {SablierV2LockupPro} contract to transfer the assets from the funder.
        params.createWithMilestones.asset.approve({ spender: address(pro), value: UINT256_MAX });

        // Calculate the broker fee amount and the net deposit amount.
        uint128 protocolFeeAmount = ud(grossDepositAmount).mul(DEFAULT_PROTOCOL_FEE).intoUint128();
        uint128 brokerFeeAmount = ud(grossDepositAmount).mul(broker.fee).intoUint128();
        uint128 netDepositAmount = grossDepositAmount - protocolFeeAmount - brokerFeeAmount;

        // Adjust the segment amounts based on the fuzzed net deposit amount.
        Segment[] memory segments = params.createWithMilestones.segments;
        adjustSegmentAmounts(segments, netDepositAmount);

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupPro} contract.
        vm.expectCall(
            address(params.createWithMilestones.asset),
            abi.encodeCall(IERC20.transferFrom, (funder, address(pro), netDepositAmount + protocolFeeAmount))
        );

        // Expect the broker fee to be paid to the broker, if the fee amount is not zero.
        if (brokerFeeAmount > 0) {
            vm.expectCall(
                address(params.createWithMilestones.asset),
                abi.encodeCall(IERC20.transferFrom, (funder, broker.addr, brokerFeeAmount))
            );
        }

        // Create the stream.
        uint256 streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            recipient,
            grossDepositAmount,
            segments,
            params.createWithMilestones.asset,
            cancelable,
            startTime,
            broker
        );

        // Assert that the stream was created.
        LockupProStream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, LockupAmounts({ deposit: netDepositAmount, withdrawn: 0 }));
        assertEq(actualStream.isCancelable, cancelable);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.segments, segments);
        assertEq(actualStream.startTime, startTime);
        assertEq(actualStream.status, defaultStream.status);
        assertEq(actualStream.asset, defaultStream.asset);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }

    /// @dev it should record the protocol fee.
    function testFuzz_CreateWithMilestones_ProtocolFee(
        uint128 grossDepositAmount,
        UD60x18 protocolFee
    )
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
        vm.assume(grossDepositAmount != 0);
        protocolFee = bound(protocolFee, 0, DEFAULT_MAX_FEE);

        // Set the fuzzed protocol fee.
        changePrank(users.admin);
        comptroller.setProtocolFee(params.createWithMilestones.asset, protocolFee);

        // Make the sender the funder in this test.
        address funder = params.createWithMilestones.sender;

        // Make the funder the caller in the rest of this test.
        changePrank(funder);

        // Mint enough assets to the funder.
        deal({ token: address(params.createWithMilestones.asset), to: funder, give: grossDepositAmount });

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = pro.getProtocolRevenues(params.createWithMilestones.asset);

        // Calculate the protocol fee amount and the net deposit amount.
        uint128 protocolFeeAmount = ud(grossDepositAmount).mul(protocolFee).intoUint128();
        uint128 netDepositAmount = grossDepositAmount - protocolFeeAmount;

        // Adjust the segment amounts based on the fuzzed net deposit amount.
        Segment[] memory segments = params.createWithMilestones.segments;
        adjustSegmentAmounts(segments, netDepositAmount);

        // Create the stream. The broker fee is disabled so that it doesn't interfere with the calculations.
        pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            grossDepositAmount,
            segments,
            params.createWithMilestones.asset,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = pro.getProtocolRevenues(params.createWithMilestones.asset);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + protocolFeeAmount;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);
    }

    /// @dev it should emit a CreateLockupProStream event.
    function test_CreateWithMilestones_Event()
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
        // Expect an event to be emitted.
        uint256 streamId = pro.nextStreamId();
        address funder = params.createWithMilestones.sender;
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLockupProStream({
            streamId: streamId,
            funder: funder,
            sender: params.createWithMilestones.sender,
            recipient: params.createWithMilestones.recipient,
            amounts: DEFAULT_CREATE_AMOUNTS,
            segments: params.createWithMilestones.segments,
            asset: params.createWithMilestones.asset,
            cancelable: params.createWithMilestones.cancelable,
            startTime: params.createWithMilestones.startTime,
            stopTime: DEFAULT_STOP_TIME,
            broker: params.createWithMilestones.broker.addr
        });

        // Create the stream.
        createDefaultStream();
    }
}
