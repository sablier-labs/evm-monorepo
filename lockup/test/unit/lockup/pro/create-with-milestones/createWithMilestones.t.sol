// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20_CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { MAX_UD60x18, UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Broker, CreateLockupAmounts, LockupAmounts, LockupProStream, Segment } from "src/types/Structs.sol";

import { ISablierV2LockupPro } from "src/interfaces/ISablierV2LockupPro.sol";

import { Pro_Test } from "../Pro.t.sol";

contract CreateWithMilestones_Pro_Test is Pro_Test {
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
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        UD60x18 brokerFee = ZERO;
        changePrank(defaultParams.createWithMilestones.sender);

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
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.grossDepositAmount,
            defaultParams.createWithMilestones.segments,
            nonContract,
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
        // Make the sender the funder in this test.
        address funder = defaultParams.createWithMilestones.sender;

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
                (funder, defaultParams.createWithMilestones.broker.addr, DEFAULT_BROKER_FEE_AMOUNT)
            )
        );

        // Create the stream.
        pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.grossDepositAmount,
            defaultParams.createWithMilestones.segments,
            IERC20(address(nonCompliantAsset)),
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );

        // Assert that the stream was created.
        LockupProStream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(address(actualStream.asset), address(nonCompliantAsset), "asset");
        assertEq(actualStream.isCancelable, defaultStream.isCancelable, "isCancelable");
        assertEq(actualStream.sender, defaultStream.sender, "sender");
        assertEq(actualStream.segments, defaultStream.segments);
        assertEq(actualStream.startTime, defaultStream.startTime, "startTime");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultParams.createWithMilestones.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }

    modifier assetERC20Compliant() {
        _;
    }

    struct Params {
        address funder;
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        bool cancelable;
        uint40 startTime;
        Broker broker;
        UD60x18 protocolFee;
    }

    struct Vars {
        uint128 initialProtocolRevenues;
        uint128 protocolFeeAmount;
        uint128 brokerFeeAmount;
        uint128 netDepositAmount;
        uint256 actualNextStreamId;
        uint256 expectedNextStreamId;
        uint256 actualProtocolRevenues;
        uint256 expectedProtocolRevenues;
        address actualNFTOwner;
        address expectedNFTOwner;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, record the protocol
    /// fee, mint the NFT, and emit a CreateLockupProStream event.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, recipient, sender, and broker.
    /// - Multiple values for the gross deposit amount.
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
        vm.assume(params.funder != address(0) && params.recipient != address(0) && params.broker.addr != address(0));
        vm.assume(params.grossDepositAmount != 0);
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        params.startTime = boundUint40(params.startTime, 0, defaultParams.createWithMilestones.segments[0].milestone);
        params.protocolFee = bound(params.protocolFee, 0, DEFAULT_MAX_FEE);

        // Set the fuzzed protocol fee.
        changePrank(users.admin);
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: params.protocolFee });

        // Make the fuzzed funder the caller in this test.
        changePrank(params.funder);

        // Mint enough assets to the fuzzed funder.
        deal({ token: address(DEFAULT_ASSET), to: params.funder, give: params.grossDepositAmount });

        // Approve the {SablierV2LockupPro} contract to transfer the assets from the funder.
        DEFAULT_ASSET.approve({ spender: address(pro), value: UINT256_MAX });

        // Load the initial protocol revenues.
        Vars memory vars;
        vars.initialProtocolRevenues = pro.getProtocolRevenues(DEFAULT_ASSET);

        // Calculate the broker fee amount and the net deposit amount.
        vars.protocolFeeAmount = ud(params.grossDepositAmount).mul(params.protocolFee).intoUint128();
        vars.brokerFeeAmount = ud(params.grossDepositAmount).mul(params.broker.fee).intoUint128();
        vars.netDepositAmount = params.grossDepositAmount - vars.protocolFeeAmount - vars.brokerFeeAmount;

        // Adjust the segment amounts based on the fuzzed net deposit amount.
        Segment[] memory segments = defaultParams.createWithMilestones.segments;
        adjustSegmentAmounts(segments, vars.netDepositAmount);

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupPro} contract.
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(
                IERC20.transferFrom,
                (params.funder, address(pro), vars.netDepositAmount + vars.protocolFeeAmount)
            )
        );

        // Expect the broker fee to be paid to the broker, if the fee amount is not zero.
        if (vars.brokerFeeAmount > 0) {
            vm.expectCall(
                address(DEFAULT_ASSET),
                abi.encodeCall(IERC20.transferFrom, (params.funder, params.broker.addr, vars.brokerFeeAmount))
            );
        }

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLockupProStream({
            streamId: streamId,
            funder: params.funder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: CreateLockupAmounts({
                netDeposit: vars.netDepositAmount,
                protocolFee: vars.protocolFeeAmount,
                brokerFee: vars.brokerFeeAmount
            }),
            segments: segments,
            asset: DEFAULT_ASSET,
            cancelable: params.cancelable,
            startTime: params.startTime,
            stopTime: DEFAULT_STOP_TIME,
            broker: params.broker.addr
        });

        // Create the stream.
        pro.createWithMilestones(
            params.sender,
            params.recipient,
            params.grossDepositAmount,
            segments,
            DEFAULT_ASSET,
            params.cancelable,
            params.startTime,
            params.broker
        );

        // Assert that the stream was created.
        LockupProStream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, LockupAmounts({ deposit: vars.netDepositAmount, withdrawn: 0 }));
        assertEq(actualStream.asset, defaultStream.asset, "asset");
        assertEq(actualStream.isCancelable, params.cancelable, "isCancelable");
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.segments, segments);
        assertEq(actualStream.startTime, params.startTime, "startTime");
        assertEq(actualStream.status, defaultStream.status);
        assertEq(actualStream.stopTime, defaultStream.stopTime, "stopTime");

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
