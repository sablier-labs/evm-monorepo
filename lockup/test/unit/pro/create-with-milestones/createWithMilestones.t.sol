// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { Amounts, ProStream, Segment } from "src/types/Structs.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

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
        segmentCount = bound(segmentCount, MAX_SEGMENT_COUNT + 1, MAX_SEGMENT_COUNT * 10);
        Segment[] memory segments = new Segment[](segmentCount);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Pro__SegmentCountTooHigh.selector, segmentCount));
        createDefaultStreamWithSegments(segments);
    }

    modifier SegmentCountNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__LoopCalculationOverflowsBlockGasLimit() external {
        // TODO
    }

    modifier LoopCalculationsDoNotOverflowBlockGasLimit() {
        _;
    }

    /// @dev When the segment amounts sum overflows, it should revert.
    function testCannotCreateWithMilestones__SegmentAmountsSumOverflows()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        LoopCalculationsDoNotOverflowBlockGasLimit
    {
        Segment[] memory segments = defaultArgs.createWithMilestones.segments;
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
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
    {
        // Swap the segment milestones.
        Segment[] memory segments = defaultArgs.createWithMilestones.segments;
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
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
    {
        depositDelta = boundUint128(depositDelta, 100, DEFAULT_GROSS_DEPOSIT_AMOUNT);

        // Disable both the protocol and the operator fee so that they don't interfere with the calculations.
        changePrank(users.owner);
        comptroller.setProtocolFee(defaultArgs.createWithMilestones.token, ZERO);
        UD60x18 operatorFee = ZERO;
        changePrank(defaultArgs.createWithMilestones.sender);

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
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            netDepositAmount,
            defaultArgs.createWithMilestones.segments,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
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
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
    {
        protocolFee = bound(protocolFee, MAX_FEE.add(ud(1)), MAX_UD60x18);

        // Set the protocol fee.
        changePrank(users.owner);
        comptroller.setProtocolFee(defaultStream.token, protocolFee);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__ProtocolFeeTooHigh.selector, protocolFee, MAX_FEE));
        createDefaultStream();
    }

    modifier ProtocolFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__OperatorFeeTooHigh(
        UD60x18 operatorFee
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
    {
        operatorFee = bound(operatorFee, MAX_FEE.add(ud(1)), MAX_UD60x18);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__OperatorFeeTooHigh.selector, operatorFee, MAX_FEE));
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segments,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
        );
    }

    modifier OperatorFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__TokenNotContract(
        address nonToken
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
        OperatorFeeNotTooHigh
    {
        vm.assume(nonToken.code.length == 0);

        // Set the default protocol fee so that the test does not revert due to the net deposit amount not being
        // equal to the segment amounts sum.
        changePrank(users.owner);
        comptroller.setProtocolFee(nonToken, DEFAULT_PROTOCOL_FEE);
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, nonToken));
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segments,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            nonToken,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
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
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
        OperatorFeeNotTooHigh
        TokenContract
    {
        // Load the stream id.
        uint256 streamId = pro.nextStreamId();

        // Make the sender the funder in this test.
        address funder = defaultArgs.createWithMilestones.sender;

        // Expect the tokens to be transferred from the funder to the SablierV2Pro contract.
        vm.expectCall(
            address(nonCompliantToken),
            abi.encodeCall(IERC20.transferFrom, (funder, address(pro), DEFAULT_NET_DEPOSIT_AMOUNT))
        );

        // Expect the operator fee to be paid to the operator.
        vm.expectCall(
            address(nonCompliantToken),
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, defaultArgs.createWithMilestones.operator, DEFAULT_OPERATOR_FEE_AMOUNT)
            )
        );

        // Create the stream.
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segments,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            address(nonCompliantToken),
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
        );

        // Assert that the stream was created.
        ProStream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(actualStream.isCancelable, defaultStream.isCancelable);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.segments, defaultStream.segments);
        assertEq(actualStream.startTime, defaultStream.startTime);
        assertEq(actualStream.token, address(nonCompliantToken));

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultArgs.createWithMilestones.recipient;
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
    /// - All possible permutations for the funder, recipient, sender, and operator.
    /// - Multiple values for the gross deposit amount.
    /// - Operator fee zero and non-zero.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time equal and not equal to the first segment milestone.
    function testCreateWithMilestones(
        address funder,
        address recipient,
        uint128 grossDepositAmount,
        address operator,
        UD60x18 operatorFee,
        bool cancelable,
        uint40 startTime
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
        OperatorFeeNotTooHigh
        TokenContract
        TokenERC20Compliant
    {
        vm.assume(funder != address(0) && recipient != address(0) && operator != address(0));
        vm.assume(grossDepositAmount != 0);
        operatorFee = bound(operatorFee, 0, MAX_FEE);
        startTime = boundUint40(startTime, 0, defaultArgs.createWithMilestones.segments[0].milestone);

        // Make the fuzzed funder the caller in this test.
        changePrank(funder);

        // Mint enough tokens to the funder.
        deal({ token: defaultArgs.createWithMilestones.token, to: funder, give: grossDepositAmount });

        // Approve the SablierV2Pro contract to transfer the tokens from the funder.
        IERC20(defaultArgs.createWithMilestones.token).approve({ spender: address(pro), value: UINT256_MAX });

        // Calculate the operator fee amount and the net deposit amount.
        uint128 protocolFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(DEFAULT_PROTOCOL_FEE)));
        uint128 operatorFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(operatorFee)));
        uint128 netDepositAmount = grossDepositAmount - protocolFeeAmount - operatorFeeAmount;

        // Adjust the segment amounts based on the fuzzed net deposit amount.
        Segment[] memory segments = defaultArgs.createWithMilestones.segments;
        adjustSegmentAmounts(segments, netDepositAmount);

        // Expect the tokens to be transferred from the funder to the SablierV2Pro contract.
        vm.expectCall(
            defaultArgs.createWithMilestones.token,
            abi.encodeCall(IERC20.transferFrom, (funder, address(pro), netDepositAmount))
        );

        // Expect the operator fee to be paid to the operator, if the fee amount is not zero.
        if (operatorFeeAmount > 0) {
            vm.expectCall(
                defaultArgs.createWithMilestones.token,
                abi.encodeCall(IERC20.transferFrom, (funder, operator, operatorFeeAmount))
            );
        }

        // Create the stream.
        uint256 streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            recipient,
            grossDepositAmount,
            segments,
            operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            cancelable,
            startTime
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
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
        OperatorFeeNotTooHigh
        TokenContract
        TokenERC20Compliant
    {
        vm.assume(grossDepositAmount != 0);
        protocolFee = bound(protocolFee, 0, MAX_FEE);

        // Set the fuzzed protocol fee.
        changePrank(users.owner);
        comptroller.setProtocolFee(defaultArgs.createWithMilestones.token, protocolFee);

        // Make the sender the funder in this test.
        address funder = defaultArgs.createWithMilestones.sender;

        // Make the funder the caller in the rest of this test.
        changePrank(funder);

        // Mint enough tokens to the funder.
        deal({ token: defaultArgs.createWithMilestones.token, to: funder, give: grossDepositAmount });

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = pro.getProtocolRevenues(defaultArgs.createWithMilestones.token);

        // Calculate the protocol fee amount and the net deposit amount.
        uint128 protocolFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(protocolFee)));
        uint128 netDepositAmount = grossDepositAmount - protocolFeeAmount;

        // Adjust the segment amounts based on the fuzzed net deposit amount.
        Segment[] memory segments = defaultArgs.createWithMilestones.segments;
        adjustSegmentAmounts(segments, netDepositAmount);

        // Disable the operator fee so that it doesn't interfere with the calculations.
        UD60x18 operatorFee = ZERO;

        // Create the stream.
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            grossDepositAmount,
            segments,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
        );

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = pro.getProtocolRevenues(defaultArgs.createWithMilestones.token);
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
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
        OperatorFeeNotTooHigh
        TokenContract
        TokenERC20Compliant
    {
        // Expect an event to be emitted.
        uint256 streamId = pro.nextStreamId();
        address funder = defaultArgs.createWithMilestones.sender;
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateProStream(
            streamId,
            funder,
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            defaultArgs.createWithMilestones.segments,
            DEFAULT_PROTOCOL_FEE_AMOUNT,
            defaultArgs.createWithMilestones.operator,
            DEFAULT_OPERATOR_FEE_AMOUNT,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
        );

        // Create the stream.
        createDefaultStream();
    }
}
