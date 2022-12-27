// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { Solarray } from "solarray/Solarray.sol";
import { stdError } from "forge-std/StdError.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { ProTest } from "../ProTest.t.sol";

contract CreateWithMilestones__Test is ProTest {
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
    /// It is not possible to obtain a zero net deposit amount from a non-zero gross deposit amount, because the
    /// `MAX_FEE` is hard coded to 10%.
    function testCannotCreateWithMilestones__NetDepositAmountZero() external RecipientNonZeroAddress {
        vm.expectRevert(Errors.SablierV2__NetDepositAmountZero.selector);
        uint128 grossDepositAmount = 0;
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            grossDepositAmount,
            defaultArgs.createWithMilestones.segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
        );
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
        uint128[] memory segmentAmounts;
        SD1x18[] memory segmentExponents;
        uint40[] memory segmentMilestones;
        vm.expectRevert(Errors.SablierV2Pro__SegmentCountZero.selector);
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            segmentAmounts,
            segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            segmentMilestones
        );
    }

    modifier SegmentCountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__SegmentCountTooHigh(
        uint256 segmentCount
    ) external RecipientNonZeroAddress NetDepositAmountNotZero SegmentCountNotZero {
        segmentCount = bound(segmentCount, MAX_SEGMENT_COUNT + 1, MAX_SEGMENT_COUNT * 10);
        uint128[] memory segmentAmounts = new uint128[](segmentCount);
        for (uint128 i = 0; i < segmentCount; ) {
            segmentAmounts[i] = i;
            unchecked {
                i += 1;
            }
        }
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Pro__SegmentCountTooHigh.selector, segmentCount));
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
        );
    }

    modifier SegmentCountNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__SegmentCountsNotEqual__SegmentExponents()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
    {
        SD1x18[] memory segmentExponents = Solarray.SD1x18s(DEFAULT_SEGMENT_EXPONENTS[0]);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__SegmentCountsNotEqual.selector,
                defaultArgs.createWithMilestones.segmentAmounts.length,
                segmentExponents.length,
                defaultArgs.createWithMilestones.segmentMilestones.length
            )
        );
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segmentAmounts,
            segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
        );
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__SegmentCountsNotEqual__SegmentMilestones()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
    {
        uint40[] memory segmentMilestones = Solarray.uint40s(DEFAULT_SEGMENT_MILESTONES[0]);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__SegmentCountsNotEqual.selector,
                defaultStream.segmentAmounts.length,
                defaultStream.segmentExponents.length,
                segmentMilestones.length
            )
        );
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            segmentMilestones
        );
    }

    modifier SegmentCountsEqual() {
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
        SegmentCountsEqual
        LoopCalculationsDoNotOverflowBlockGasLimit
    {
        uint128[] memory segmentAmounts = Solarray.uint128s(UINT128_MAX, 1);
        vm.expectRevert(stdError.arithmeticError);
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
        );
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
        SegmentCountsEqual
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
    {
        uint40[] memory segmentMilestones = Solarray.uint40s(
            DEFAULT_SEGMENT_MILESTONES[1],
            DEFAULT_SEGMENT_MILESTONES[0]
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__SegmentMilestonesNotOrdered.selector,
                1,
                segmentMilestones[0],
                segmentMilestones[1]
            )
        );
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            segmentMilestones
        );
    }

    modifier SegmentMilestonesOrdered() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithMilestones__NetDepositAmountNotEqualToSegmentAmountsSum(
        uint128 delta
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentCountsEqual
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
    {
        delta = boundUint128(delta, 100, DEFAULT_GROSS_DEPOSIT_AMOUNT);

        // Disable both the protocol and the operator fee so that they don't interfere with the calculations.
        changePrank(users.owner);
        comptroller.setProtocolFee(defaultArgs.createWithMilestones.token, ZERO);
        UD60x18 operatorFee = ZERO;
        changePrank(users.sender);

        // Adjust the default net deposit amount.
        uint128 netDepositAmount = DEFAULT_NET_DEPOSIT_AMOUNT + delta;

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
            defaultArgs.createWithMilestones.segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
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
        SegmentCountsEqual
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
        SegmentCountsEqual
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
            defaultArgs.createWithMilestones.segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
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
        SegmentCountsEqual
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
        OperatorFeeNotTooHigh
    {
        vm.assume(nonToken.code.length == 0);

        // Set the protocol fee so that the test does not revert due to the net deposit amount not being equal
        // to the segment amounts sum.
        changePrank(users.owner);
        comptroller.setProtocolFee(nonToken, DEFAULT_PROTOCOL_FEE);
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, nonToken));
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            nonToken,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
        );
    }

    modifier TokenContract() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, record the protocol fee, bump the next
    /// stream id, and mint the NFT.
    function testCreateWithMilestones__TokenMissingReturnValue()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentCountsEqual
        LoopCalculationsDoNotOverflowBlockGasLimit
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        NetDepositAmountEqualToSegmentAmountsSum
        ProtocolFeeNotTooHigh
        OperatorFeeNotTooHigh
        TokenContract
    {
        // Load the protocol revenues.
        uint128 previousProtocolRevenues = pro.getProtocolRevenues(address(nonCompliantToken));

        // Load the stream id.
        uint256 streamId = pro.nextStreamId();

        // Expect the tokens to be transferred from the funder to the SablierV2Pro contract.
        address funder = defaultArgs.createWithMilestones.sender;
        vm.expectCall(
            address(nonCompliantToken),
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, address(pro), defaultArgs.createWithMilestones.grossDepositAmount)
            )
        );

        // Expect the the operator fee to be paid to the operator.
        vm.expectCall(
            address(nonCompliantToken),
            abi.encodeCall(IERC20.transfer, (defaultArgs.createWithMilestones.operator, DEFAULT_OPERATOR_FEE_AMOUNT))
        );

        // Create the stream.
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            address(nonCompliantToken),
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
        );

        // Assert that the stream was created.
        DataTypes.ProStream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.depositAmount, DEFAULT_NET_DEPOSIT_AMOUNT);
        assertEq(actualStream.isCancelable, defaultStream.isCancelable);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEqUint128Array(actualStream.segmentAmounts, defaultStream.segmentAmounts);
        assertEq(actualStream.segmentExponents, defaultStream.segmentExponents);
        assertEqUint40Array(actualStream.segmentMilestones, defaultStream.segmentMilestones);
        assertEq(actualStream.startTime, defaultStream.startTime);
        assertEq(actualStream.stopTime, DEFAULT_STOP_TIME);
        assertEq(actualStream.token, address(nonCompliantToken));
        assertEq(actualStream.withdrawnAmount, defaultStream.withdrawnAmount);

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = pro.getProtocolRevenues(address(nonCompliantToken));
        uint128 expectedProtocolRevenues = previousProtocolRevenues + DEFAULT_PROTOCOL_FEE_AMOUNT;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);

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
    /// - All possible permutations between the funder, recipient, sender, and operator.
    /// - Protocol fee zero and non-zero.
    /// - Operator fee zero and non-zero.
    /// - Start time in the past, present and future.
    /// - Start time equal and not equal to the first segment milestone.
    function testCreateWithMilestones(
        address funder,
        address recipient,
        uint128 grossDepositAmount,
        UD60x18 protocolFee,
        address operator,
        UD60x18 operatorFee,
        uint40 startTime
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentCountsEqual
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
        protocolFee = bound(protocolFee, 0, MAX_FEE);
        operatorFee = bound(operatorFee, 0, MAX_FEE);
        startTime = boundUint40(startTime, 0, defaultArgs.createWithMilestones.segmentMilestones[0]);

        // Set the fuzzed protocol fee.
        changePrank(users.owner);
        comptroller.setProtocolFee(defaultArgs.createWithMilestones.token, protocolFee);

        // Make the funder the caller in the rest of this test.
        changePrank(funder);

        // Mint tokens to the funder.
        deal({ token: defaultArgs.createWithMilestones.token, to: funder, give: grossDepositAmount });

        // Approve the SablierV2Pro contract to transfer the tokens from the funder.
        IERC20(defaultArgs.createWithMilestones.token).approve({ spender: address(pro), value: UINT256_MAX });

        // Load the protocol revenues.
        uint128 previousProtocolRevenues = pro.getProtocolRevenues(defaultArgs.createWithMilestones.token);

        // Calculate the fee amounts and the net deposit amount.
        (uint128 protocolFeeAmount, uint128 operatorFeeAmount, uint128 netDepositAmount) = calculateFeeAmounts(
            grossDepositAmount,
            protocolFee,
            operatorFee
        );

        // Calculate the segment amounts.
        uint128[] memory segmentAmounts = calculateSegmentAmounts(netDepositAmount);

        // Expect the tokens to be transferred from the funder to the SablierV2Pro contract.
        vm.expectCall(
            defaultArgs.createWithMilestones.token,
            abi.encodeCall(IERC20.transferFrom, (funder, address(pro), grossDepositAmount))
        );

        // Expect the the operator fee to be paid to the operator, if the fee amount is not zero.
        if (operatorFeeAmount > 0) {
            vm.expectCall(
                defaultArgs.createWithMilestones.token,
                abi.encodeCall(IERC20.transfer, (operator, operatorFeeAmount))
            );
        }

        // Create the stream.
        uint256 streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            recipient,
            grossDepositAmount,
            segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            startTime,
            defaultArgs.createWithMilestones.segmentMilestones
        );

        // Assert that the stream was created.
        DataTypes.ProStream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.depositAmount, netDepositAmount);
        assertEq(actualStream.isCancelable, defaultStream.isCancelable);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEqUint128Array(actualStream.segmentAmounts, segmentAmounts);
        assertEq(actualStream.segmentExponents, defaultStream.segmentExponents);
        assertEqUint40Array(actualStream.segmentMilestones, defaultStream.segmentMilestones);
        assertEq(actualStream.startTime, startTime);
        assertEq(actualStream.stopTime, DEFAULT_STOP_TIME);
        assertEq(actualStream.token, defaultStream.token);
        assertEq(actualStream.withdrawnAmount, defaultStream.withdrawnAmount);

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = pro.getProtocolRevenues(defaultArgs.createWithMilestones.token);
        uint128 expectedProtocolRevenues = previousProtocolRevenues + protocolFeeAmount;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }

    /// @dev it should emit a CreateProStream event.
    function testCreateWithMilestones__Event()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        SegmentCountNotZero
        SegmentCountNotTooHigh
        SegmentCountsEqual
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
            defaultArgs.createWithMilestones.segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            DEFAULT_PROTOCOL_FEE_AMOUNT,
            defaultArgs.createWithMilestones.operator,
            DEFAULT_OPERATOR_FEE_AMOUNT,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
        );

        // Create the stream.
        pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
        );
    }
}
