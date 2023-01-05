// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { Amounts, Broker, ProStream, Segment } from "src/types/Structs.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { ISablierV2Pro } from "src/interfaces/ISablierV2Pro.sol";

import { ProTest } from "../ProTest.t.sol";

contract CreateWithMilestones__ProTest is ProTest {
    /// @dev it should revert.
    function testCannotCreateWithMilestones__RecipientZeroAddress() external {
        vm.expectRevert("ERC721: mint to the zero address");
        address recipient = address(0);
        createDefaultStreamWithRecipient(recipient);
    }

    modifier RecipientNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    ///
    /// It is not possible (in principle) to obtain a zero net deposit amount from a non-zero gross deposit amount,
    /// because we hard-code the `MAX_FEE` to 10%.
    function testCannotCreateWithMilestones__NetDepositAmountZero() external RecipientNonZeroAddress {
        vm.expectRevert(Errors.SablierV2__NetDepositAmountZero.selector);
        uint128 grossDepositAmount = 0;
        createDefaultStreamWithGrossDepositAmount(grossDepositAmount);
    }

    modifier NetDepositAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__SegmentCountZero()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
    {
        Segment[] memory segments;
        vm.expectRevert(Errors.SablierV2Pro__SegmentCountZero.selector);
        createDefaultStreamWithSegments(segments);
    }

    modifier SegmentCountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__SegmentCountTooHigh(
        uint256 segmentCount
    ) external RecipientNonZeroAddress NetDepositAmountNotZero SegmentCountNotZero {
        segmentCount = bound(segmentCount, DEFAULT_MAX_SEGMENT_COUNT + 1, DEFAULT_MAX_SEGMENT_COUNT * 10);
        Segment[] memory segments = new Segment[](segmentCount);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Pro__SegmentCountTooHigh.selector, segmentCount));
        createDefaultStreamWithSegments(segments);
    }

    modifier SegmentCountNotTooHigh() {
        _;
    }

    /// @dev When the segment amounts sum overflows, it should revert.
    function testCannotCreateWithMilestones__SegmentAmountsSumOverflows()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
    {
        Segment[] memory segments = params.createWithMilestones.segments;
        segments[0].amount = UINT128_MAX;
        segments[1].amount = 1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStreamWithSegments(segments);
    }

    modifier SegmentAmountsSumDoesNotOverflow() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__SegmentMilestonesNotOrdered()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentAmountsSumDoesNotOverflow
    {
        // Swap the segment milestones.
        Segment[] memory segments = params.createWithMilestones.segments;
        (segments[0].milestone, segments[1].milestone) = (segments[1].milestone, segments[0].milestone);

        // Expect an error.
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__SegmentMilestonesNotOrdered.selector,
                index,
                segments[0].milestone,
                segments[1].milestone
            )
        );

        // Create the stream.
        createDefaultStreamWithSegments(segments);
    }

    modifier SegmentMilestonesOrdered() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__NetDepositAmountNotEqualToSegmentAmountsSum(
        uint128 depositDelta
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
    {
        depositDelta = boundUint128(depositDelta, 100, DEFAULT_GROSS_DEPOSIT_AMOUNT);

        // Disable both the protocol and the broker fee so that they don't interfere with the calculations.
        changePrank(users.owner);
        comptroller.setProtocolFee(params.createWithMilestones.token, ZERO);
        UD60x18 brokerFee = ZERO;
        changePrank(params.createWithMilestones.sender);

        // Adjust the default net deposit amount.
        uint128 netDepositAmount = DEFAULT_NET_DEPOSIT_AMOUNT + depositDelta;

        // Expect an error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__NetDepositAmountNotEqualToSegmentAmountsSum.selector,
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
            params.createWithMilestones.token,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: brokerFee })
        );
    }

    modifier NetDepositAmountEqualToSegmentAmountsSum() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__ProtocolFeeTooHigh(
        UD60x18 protocolFee
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
    {
        protocolFee = bound(protocolFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);

        // Set the protocol fee.
        changePrank(users.owner);
        comptroller.setProtocolFee(defaultStream.token, protocolFee);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__ProtocolFeeTooHigh.selector, protocolFee, DEFAULT_MAX_FEE)
        );
        createDefaultStream();
    }

    modifier ProtocolFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__BrokerFeeTooHigh(
        UD60x18 brokerFee
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
    {
        brokerFee = bound(brokerFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__BrokerFeeTooHigh.selector, brokerFee, DEFAULT_MAX_FEE)
        );
        pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            params.createWithMilestones.grossDepositAmount,
            params.createWithMilestones.segments,
            params.createWithMilestones.token,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            Broker({ addr: users.broker, fee: brokerFee })
        );
    }

    modifier BrokerFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__TokenNotContract(
        IERC20 nonToken
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
        BrokerFeeNotTooHigh
    {
        vm.assume(address(nonToken).code.length == 0);

        // Set the default protocol fee so that the test does not revert due to the net deposit amount not being
        // equal to the segment amounts sum.
        changePrank(users.owner);
        comptroller.setProtocolFee(nonToken, DEFAULT_PROTOCOL_FEE);
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(nonToken)));
        pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            params.createWithMilestones.grossDepositAmount,
            params.createWithMilestones.segments,
            nonToken,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            params.createWithMilestones.broker
        );
    }

    modifier TokenContract() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, and mint the NFT.
    function testCreateWithMilestones__TokenMissingReturnValue()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
        BrokerFeeNotTooHigh
        TokenContract
    {
        // Load the stream id.
        uint256 streamId = pro.nextStreamId();

        // Make the sender the funder in this test.
        address funder = params.createWithMilestones.sender;

        // Expect the tokens to be transferred from the funder to the SablierV2Pro contract.
        vm.expectCall(
            address(nonCompliantToken),
            abi.encodeCall(IERC20.transferFrom, (funder, address(pro), DEFAULT_NET_DEPOSIT_AMOUNT))
        );

        // Expect the broker fee to be paid to the broker.
        vm.expectCall(
            address(nonCompliantToken),
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
            IERC20(address(nonCompliantToken)),
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            params.createWithMilestones.broker
        );

        // Assert that the stream was created.
        ProStream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(actualStream.isCancelable, defaultStream.isCancelable);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.segments, defaultStream.segments);
        assertEq(actualStream.startTime, defaultStream.startTime);
        assertEq(actualStream.token, IERC20(address(nonCompliantToken)));

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = params.createWithMilestones.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }

    modifier TokenERC20Compliant() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, emit a CreateProStream event, create the stream, record the
    /// protocol fee, bump the next stream id, and mint the NFT.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, recipient, sender, and broker.
    /// - Multiple values for the gross deposit amount.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time equal and not equal to the first segment milestone.
    /// - Broker fee zero and non-zero.
    function testCreateWithMilestones(
        address funder,
        address recipient,
        uint128 grossDepositAmount,
        bool cancelable,
        uint40 startTime,
        Broker memory broker
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
        BrokerFeeNotTooHigh
        TokenContract
        TokenERC20Compliant
    {
        vm.assume(funder != address(0) && recipient != address(0) && broker.addr != address(0));
        vm.assume(grossDepositAmount != 0);
        broker.fee = bound(broker.fee, 0, DEFAULT_MAX_FEE);
        startTime = boundUint40(startTime, 0, params.createWithMilestones.segments[0].milestone);

        // Make the fuzzed funder the caller in this test.
        changePrank(funder);

        // Mint enough tokens to the funder.
        deal({ token: address(params.createWithMilestones.token), to: funder, give: grossDepositAmount });

        // Approve the SablierV2Pro contract to transfer the tokens from the funder.
        params.createWithMilestones.token.approve({ spender: address(pro), value: UINT256_MAX });

        // Calculate the broker fee amount and the net deposit amount.
        uint128 protocolFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(DEFAULT_PROTOCOL_FEE)));
        uint128 brokerFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(broker.fee)));
        uint128 netDepositAmount = grossDepositAmount - protocolFeeAmount - brokerFeeAmount;

        // Adjust the segment amounts based on the fuzzed net deposit amount.
        Segment[] memory segments = params.createWithMilestones.segments;
        adjustSegmentAmounts(segments, netDepositAmount);

        // Expect the tokens to be transferred from the funder to the SablierV2Pro contract.
        vm.expectCall(
            address(params.createWithMilestones.token),
            abi.encodeCall(IERC20.transferFrom, (funder, address(pro), netDepositAmount))
        );

        // Expect the broker fee to be paid to the broker, if the fee amount is not zero.
        if (brokerFeeAmount > 0) {
            vm.expectCall(
                address(params.createWithMilestones.token),
                abi.encodeCall(IERC20.transferFrom, (funder, broker.addr, brokerFeeAmount))
            );
        }

        // Create the stream.
        uint256 streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            recipient,
            grossDepositAmount,
            segments,
            params.createWithMilestones.token,
            cancelable,
            startTime,
            broker
        );

        // Assert that the stream was created.
        ProStream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, Amounts({ deposit: netDepositAmount, withdrawn: 0 }));
        assertEq(actualStream.isCancelable, cancelable);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.segments, segments);
        assertEq(actualStream.startTime, startTime);
        assertEq(actualStream.token, defaultStream.token);

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
    function testCreateWithMilestones__ProtocolFee(
        uint128 grossDepositAmount,
        UD60x18 protocolFee
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
        BrokerFeeNotTooHigh
        TokenContract
        TokenERC20Compliant
    {
        vm.assume(grossDepositAmount != 0);
        protocolFee = bound(protocolFee, 0, DEFAULT_MAX_FEE);

        // Set the fuzzed protocol fee.
        changePrank(users.owner);
        comptroller.setProtocolFee(params.createWithMilestones.token, protocolFee);

        // Make the sender the funder in this test.
        address funder = params.createWithMilestones.sender;

        // Make the funder the caller in the rest of this test.
        changePrank(funder);

        // Mint enough tokens to the funder.
        deal({ token: address(params.createWithMilestones.token), to: funder, give: grossDepositAmount });

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = pro.getProtocolRevenues(params.createWithMilestones.token);

        // Calculate the protocol fee amount and the net deposit amount.
        uint128 protocolFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(protocolFee)));
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
            params.createWithMilestones.token,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = pro.getProtocolRevenues(params.createWithMilestones.token);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + protocolFeeAmount;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);
    }

    /// @dev it should emit a CreateProStream event.
    function testCreateWithMilestones__Event()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
        BrokerFeeNotTooHigh
        TokenContract
        TokenERC20Compliant
    {
        // Expect an event to be emitted.
        uint256 streamId = pro.nextStreamId();
        address funder = params.createWithMilestones.sender;
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateProStream({
            streamId: streamId,
            funder: funder,
            sender: params.createWithMilestones.sender,
            recipient: params.createWithMilestones.recipient,
            amounts: DEFAULT_CREATE_AMOUNTS,
            segments: params.createWithMilestones.segments,
            token: params.createWithMilestones.token,
            cancelable: params.createWithMilestones.cancelable,
            startTime: params.createWithMilestones.startTime,
            broker: params.createWithMilestones.broker.addr
        });

        // Create the stream.
        createDefaultStream();
    }
}
