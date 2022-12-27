// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { MAX_UD60x18, UD60x18, ud } from "@prb/math/UD60x18.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract CreateWithRange__Test is LinearTest {
    /// @dev it should revert.
    function testCannotCreateWithRange__RecipientZeroAddress() external {
        vm.expectRevert("ERC721: mint to the zero address");
        createDefaultStreamWithRecipient({ recipient: address(0) });
    }

    modifier RecipientNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    ///
    /// It is not possible to obtain a zero net deposit amount from a non-zero gross deposit amount, because the
    /// `MAX_FEE` is hard coded to 10%.
    function testCannotCreateWithRange__NetDepositAmountZero() external RecipientNonZeroAddress {
        vm.expectRevert(Errors.SablierV2__NetDepositAmountZero.selector);
        uint128 grossDepositAmount = 0;
        linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );
    }

    modifier NetDepositAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithRange__StartTimeGreaterThanCliffTime()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
    {
        uint40 startTime = defaultStream.cliffTime;
        uint40 cliffTime = defaultStream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Linear__StartTimeGreaterThanCliffTime.selector, startTime, cliffTime)
        );
        linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            startTime,
            cliffTime,
            defaultArgs.createWithRange.stopTime
        );
    }

    modifier StartTimeLessThanOrEqualToCliffTime() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithRange__CliffTimeGreaterThanStopTime(
        uint40 cliffTime,
        uint40 stopTime
    ) external RecipientNonZeroAddress NetDepositAmountNotZero StartTimeLessThanOrEqualToCliffTime {
        vm.assume(cliffTime > stopTime);
        vm.assume(stopTime > defaultArgs.createWithRange.startTime);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Linear__CliffTimeGreaterThanStopTime.selector, cliffTime, stopTime)
        );
        linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            cliffTime,
            stopTime
        );
    }

    modifier CliffLessThanOrEqualToStopTime() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithRange__ProtocolFeeTooHigh(
        UD60x18 protocolFee
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
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
    function testCannotCreateWithRange__OperatorFeeTooHigh(
        UD60x18 operatorFee
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
        ProtocolFeeNotTooHigh
    {
        operatorFee = bound(operatorFee, MAX_FEE.add(ud(1)), MAX_UD60x18);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__OperatorFeeTooHigh.selector, operatorFee, MAX_FEE));
        linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );
    }

    modifier OperatorFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithRange__TokenNotContract(
        address nonToken
    )
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
    {
        vm.assume(nonToken.code.length == 0);
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(nonToken)));
        linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            nonToken,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );
    }

    modifier TokenContract() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, emit a CreateLinearStream event, create the stream, record the
    /// protocol fee, bump the next stream id, and mint the NFT.
    function testCreateWithRange__TokenMissingReturnValue()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
        TokenContract
    {
        // Load the protocol revenues.
        uint128 previousProtocolRevenues = linear.getProtocolRevenues(address(nonCompliantToken));

        // Load the stream id.
        uint256 streamId = linear.nextStreamId();

        // Expect the tokens to be transferred from the funder to the SablierV2Linear contract.
        address funder = defaultArgs.createWithRange.sender;
        vm.expectCall(
            address(nonCompliantToken),
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, address(linear), defaultArgs.createWithRange.grossDepositAmount)
            )
        );

        // Expect the the operator fee to be paid to the operator.
        vm.expectCall(
            address(nonCompliantToken),
            abi.encodeCall(IERC20.transfer, (defaultArgs.createWithRange.operator, DEFAULT_OPERATOR_FEE_AMOUNT))
        );

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLinearStream(
            streamId,
            funder,
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            DEFAULT_PROTOCOL_FEE_AMOUNT,
            defaultArgs.createWithRange.operator,
            DEFAULT_OPERATOR_FEE_AMOUNT,
            address(nonCompliantToken),
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );

        // Create the stream.
        linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            address(nonCompliantToken),
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );

        // Assert that the stream was created.
        DataTypes.LinearStream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.cliffTime, defaultStream.cliffTime);
        assertEq(actualStream.depositAmount, defaultStream.depositAmount);
        assertEq(actualStream.isCancelable, defaultStream.isCancelable);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.startTime, defaultStream.startTime);
        assertEq(actualStream.stopTime, defaultStream.stopTime);
        assertEq(actualStream.token, address(nonCompliantToken));
        assertEq(actualStream.withdrawnAmount, defaultStream.withdrawnAmount);

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = linear.getProtocolRevenues(address(nonCompliantToken));
        uint128 expectedProtocolRevenues = previousProtocolRevenues + DEFAULT_PROTOCOL_FEE_AMOUNT;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = linear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = linear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultArgs.createWithRange.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }

    modifier TokenERC20Compliant() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, emit a CreateLinearStream event, create the stream, record the
    /// protocol fee, bump the next stream id, and mint the NFT.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations between the funder, recipient, sender, and operator.
    /// - Start time in the past, present and future.
    /// - Start time lower than and equal to cliff time.
    /// - Cliff time lower than and equal to stop time.
    /// - Protocol fee zero and non-zero.
    /// - Operator fee zero and non-zero.
    function testCreateWithRange(
        address funder,
        address recipient,
        uint128 grossDepositAmount,
        UD60x18 protocolFee,
        address operator,
        UD60x18 operatorFee,
        uint40 startTime,
        uint40 cliffTime,
        uint40 stopTime
    )
        external
        NetDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
        TokenContract
        TokenERC20Compliant
    {
        vm.assume(funder != address(0) && recipient != address(0) && operator != address(0));
        vm.assume(grossDepositAmount != 0);
        vm.assume(startTime <= cliffTime && cliffTime <= stopTime);
        protocolFee = bound(protocolFee, 0, MAX_FEE);
        operatorFee = bound(operatorFee, 0, MAX_FEE);

        // Set the fuzzed protocol fee.
        changePrank(users.owner);
        comptroller.setProtocolFee(defaultArgs.createWithRange.token, protocolFee);

        // Make the funder the caller in the rest of this test.
        changePrank(funder);

        // Mint tokens to the funder.
        deal({ token: defaultArgs.createWithRange.token, to: funder, give: grossDepositAmount });

        // Approve the SablierV2Linear contract to transfer the tokens from the funder.
        IERC20(defaultArgs.createWithRange.token).approve({ spender: address(linear), value: UINT256_MAX });

        // Load the protocol revenues.
        uint128 previousProtocolRevenues = linear.getProtocolRevenues(defaultArgs.createWithRange.token);

        // Load the stream id.
        uint256 streamId = linear.nextStreamId();

        // Calculate the fee amounts and the net deposit amount.
        (uint128 protocolFeeAmount, uint128 operatorFeeAmount, uint128 netDepositAmount) = calculateFeeAmounts(
            grossDepositAmount,
            protocolFee,
            operatorFee
        );

        // Expect the tokens to be transferred from the funder to the SablierV2Linear contract.
        vm.expectCall(
            defaultArgs.createWithRange.token,
            abi.encodeCall(IERC20.transferFrom, (funder, address(linear), grossDepositAmount))
        );

        // Expect the the operator fee to be paid to the operator, if the fee amount is not zero.
        if (operatorFeeAmount > 0) {
            vm.expectCall(
                defaultArgs.createWithRange.token,
                abi.encodeCall(IERC20.transfer, (operator, operatorFeeAmount))
            );
        }

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLinearStream(
            streamId,
            funder,
            defaultArgs.createWithRange.sender,
            recipient,
            netDepositAmount,
            protocolFeeAmount,
            operator,
            operatorFeeAmount,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            startTime,
            cliffTime,
            stopTime
        );

        // Create the stream.
        linear.createWithRange(
            defaultArgs.createWithRange.sender,
            recipient,
            grossDepositAmount,
            operator,
            operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            startTime,
            cliffTime,
            stopTime
        );

        // Assert that the stream was created.
        DataTypes.LinearStream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.depositAmount, netDepositAmount);
        assertEq(actualStream.isCancelable, defaultStream.isCancelable);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.startTime, startTime);
        assertEq(actualStream.stopTime, stopTime);
        assertEq(actualStream.token, defaultStream.token);
        assertEq(actualStream.withdrawnAmount, defaultStream.withdrawnAmount);

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = linear.getProtocolRevenues(defaultArgs.createWithRange.token);
        uint128 expectedProtocolRevenues = previousProtocolRevenues + protocolFeeAmount;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = linear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = linear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }
}
