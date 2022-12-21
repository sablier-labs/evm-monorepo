// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { MAX_UD60x18, UD60x18, ud, unwrap, wrap } from "@prb/math/UD60x18.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract CreateWithRange__Test is SablierV2LinearTest {
    /// @dev it should revert.
    function testCannotCreateWithRange__RecipientZeroAddress() external {
        vm.expectRevert("ERC721: mint to the zero address");
        createDefaultStreamWithRecipient({ recipient: address(0) });
    }

    modifier RecipientNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithRange__GrossDepositAmountZero() external RecipientNonZeroAddress {
        vm.expectRevert(Errors.SablierV2__GrossDepositAmountZero.selector);
        uint128 grossDepositAmount = 0;
        sablierV2Linear.createWithRange(
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

    modifier GrossDepositAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithRange__StartTimeGreaterThanCliffTime()
        external
        RecipientNonZeroAddress
        GrossDepositAmountNotZero
    {
        uint40 startTime = defaultStream.cliffTime;
        uint40 cliffTime = defaultStream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Linear__StartTimeGreaterThanCliffTime.selector, startTime, cliffTime)
        );
        sablierV2Linear.createWithRange(
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
    function testCannotCreateWithRange__CliffTimeGreaterThanStopTime(uint40 cliffTime, uint40 stopTime)
        external
        RecipientNonZeroAddress
        GrossDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
    {
        vm.assume(cliffTime > stopTime);
        vm.assume(stopTime > defaultArgs.createWithRange.startTime);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Linear__CliffTimeGreaterThanStopTime.selector, cliffTime, stopTime)
        );
        sablierV2Linear.createWithRange(
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
    function testCannotCreateWithRange__ProtocolFeeTooHigh(UD60x18 protocolFee)
        external
        RecipientNonZeroAddress
        GrossDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
    {
        protocolFee = bound(protocolFee, MAX_FEE.add(ud(1)), MAX_UD60x18);

        // Set the protocol fee.
        changePrank(users.owner);
        sablierV2Comptroller.setProtocolFee(address(dai), protocolFee);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__ProtocolFeeTooHigh.selector, protocolFee, MAX_FEE));
        createDefaultStream();
    }

    modifier ProtocolFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithRange__OperatorFeeTooHigh(UD60x18 operatorFee)
        external
        RecipientNonZeroAddress
        GrossDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
        ProtocolFeeNotTooHigh
    {
        operatorFee = bound(operatorFee, MAX_FEE.add(ud(1)), MAX_UD60x18);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__OperatorFeeTooHigh.selector, operatorFee, MAX_FEE));
        sablierV2Linear.createWithRange(
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
    function testCannotCreateWithRange__TokenNotContract()
        external
        RecipientNonZeroAddress
        GrossDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
    {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        address token = address(6174);
        sablierV2Linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );
    }

    modifier TokenContract() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, emit a CreateLinearStream event, create the stream, mint the NFT
    /// and bump the next stream id.
    function testCreateWithRange__TokenMissingReturnValue()
        external
        RecipientNonZeroAddress
        GrossDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
        TokenContract
    {
        // Expect the tokens to be transferred from the funder to the SablierV2Linear contract, and the operator fee
        // to be paid to the operator.
        address token = address(nonCompliantToken);
        address funder = defaultArgs.createWithRange.sender;
        vm.expectCall(
            token,
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, address(sablierV2Linear), defaultArgs.createWithRange.grossDepositAmount)
            )
        );

        // Expect the the operator fee to be paid to the operator, if the fee amount is not zero.
        vm.expectCall(
            token,
            abi.encodeCall(IERC20.transfer, (defaultArgs.createWithRange.operator, DEFAULT_OPERATOR_FEE_AMOUNT))
        );

        // Expect an event to be emitted.
        uint256 streamId = sablierV2Linear.nextStreamId();
        uint128 protocolFeeAmount = 0;
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLinearStream(
            streamId,
            funder,
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            protocolFeeAmount,
            defaultArgs.createWithRange.operator,
            DEFAULT_OPERATOR_FEE_AMOUNT,
            token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );

        // Create the stream.
        sablierV2Linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );

        // Assert that the stream was created.
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(streamId);
        assertEq(actualStream.cancelable, defaultStream.cancelable);
        assertEq(actualStream.cliffTime, defaultStream.cliffTime);
        assertEq(actualStream.depositAmount, defaultStream.depositAmount);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.startTime, defaultStream.startTime);
        assertEq(actualStream.stopTime, defaultStream.stopTime);
        assertEq(actualStream.token, token);
        assertEq(actualStream.withdrawnAmount, defaultStream.withdrawnAmount);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualRecipient = sablierV2Linear.getRecipient(streamId);
        address expectedRecipient = defaultArgs.createWithRange.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier TokenERC20Compliant() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, emit a CreateLinearStream event, create the stream, mint the NFT
    /// and bump the next stream id.
    function testCreateWithRange(
        address funder,
        address recipient,
        uint128 grossDepositAmount,
        UD60x18 protocolFee,
        address operator,
        UD60x18 operatorFee,
        uint40 startTime,
        uint40 cliffTime,
        uint40 stopTime,
        uint8 decimals
    )
        external
        GrossDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
        TokenContract
        TokenERC20Compliant
    {
        vm.assume(funder != address(0));
        vm.assume(recipient != address(0));
        vm.assume(grossDepositAmount > 0);
        vm.assume(operator != address(0));
        vm.assume(startTime <= cliffTime);
        vm.assume(cliffTime <= stopTime);
        protocolFee = bound(protocolFee, 0, MAX_FEE);
        operatorFee = bound(operatorFee, 0, MAX_FEE);

        // Create the token with the fuzzed decimals and mint tokens to the funder.
        address token = deployAndDealToken({ decimals: decimals, user: funder, give: grossDepositAmount });

        // Set the protocol fee.
        changePrank(users.owner);
        sablierV2Comptroller.setProtocolFee(token, protocolFee);

        // Make the funder the caller in the rest of this test.
        changePrank(funder);

        // Approve the SablierV2Linear contract to transfer the tokens.
        IERC20(token).approve({ spender: address(sablierV2Linear), value: UINT256_MAX });

        // Query the next stream id.
        uint256 streamId = sablierV2Linear.nextStreamId();

        // Calculate the fee amounts and the net deposit amount.
        uint128 protocolFeeAmount = uint128(unwrap(wrap(grossDepositAmount).mul(protocolFee)));
        uint128 operatorFeeAmount = uint128(unwrap(wrap(grossDepositAmount).mul(operatorFee)));
        uint128 depositAmount = grossDepositAmount - protocolFeeAmount - operatorFeeAmount;

        // Expect the tokens to be transferred from the funder to the SablierV2Linear contract, and the operator fee
        // to be paid to the operator.
        vm.expectCall(
            address(token),
            abi.encodeCall(IERC20.transferFrom, (funder, address(sablierV2Linear), grossDepositAmount))
        );

        // Expect the the operator fee to be paid to the operator, if the fee amount is not zero.
        if (operatorFeeAmount > 0) {
            vm.expectCall(address(token), abi.encodeCall(IERC20.transfer, (operator, operatorFeeAmount)));
        }

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLinearStream(
            streamId,
            funder,
            defaultArgs.createWithRange.sender,
            recipient,
            depositAmount,
            protocolFeeAmount,
            operator,
            operatorFeeAmount,
            address(token),
            defaultArgs.createWithRange.cancelable,
            startTime,
            cliffTime,
            stopTime
        );

        // Create the stream.
        sablierV2Linear.createWithRange(
            defaultArgs.createWithRange.sender,
            recipient,
            grossDepositAmount,
            operator,
            operatorFee,
            address(token),
            defaultArgs.createWithRange.cancelable,
            startTime,
            cliffTime,
            stopTime
        );

        // Assert that the stream has been created.
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(streamId);
        assertEq(actualStream.cancelable, defaultStream.cancelable);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.depositAmount, depositAmount);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.startTime, startTime);
        assertEq(actualStream.stopTime, stopTime);
        assertEq(actualStream.token, address(token));
        assertEq(actualStream.withdrawnAmount, defaultStream.withdrawnAmount);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT has been minted.
        address actualRecipient = sablierV2Linear.getRecipient(streamId);
        address expectedRecipient = recipient;
        assertEq(actualRecipient, expectedRecipient);
    }
}
