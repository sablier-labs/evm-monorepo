// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud } from "@prb/math/UD60x18.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";

import { Amounts, LinearStream, Range } from "src/types/Structs.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract CreateWithRange__LinearTest is LinearTest {
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
        createDefaultStreamWithGrossDepositAmount(0);
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
        uint40 startTime = defaultArgs.createWithRange.range.cliff;
        uint40 cliffTime = defaultArgs.createWithRange.range.start;
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
            Range({ start: startTime, cliff: cliffTime, stop: defaultArgs.createWithRange.range.stop })
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
        vm.assume(stopTime > defaultArgs.createWithRange.range.start);

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
            Range({ start: defaultArgs.createWithRange.range.start, cliff: cliffTime, stop: stopTime })
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
            defaultArgs.createWithRange.range
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
            defaultArgs.createWithRange.range
        );
    }

    modifier TokenContract() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, and mint the NFT.
    function testCreateWithRange__TokenMissingReturnValue()
        external
        RecipientNonZeroAddress
        NetDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
        TokenContract
    {
        // Load the stream id.
        uint256 streamId = linear.nextStreamId();

        // Expect the tokens to be transferred from the funder to the SablierV2Linear contract.
        address funder = defaultArgs.createWithRange.sender;
        vm.expectCall(
            address(nonCompliantToken),
            abi.encodeCall(IERC20.transferFrom, (funder, address(linear), DEFAULT_NET_DEPOSIT_AMOUNT))
        );

        // Expect the operator fee to be paid to the operator.
        vm.expectCall(
            address(nonCompliantToken),
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, defaultArgs.createWithRange.operator, DEFAULT_OPERATOR_FEE_AMOUNT)
            )
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
            defaultArgs.createWithRange.range
        );

        // Assert that the stream was created.
        LinearStream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(actualStream.isCancelable, defaultStream.isCancelable);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.range, defaultStream.range);
        assertEq(actualStream.token, address(nonCompliantToken));

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

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, and mint the NFT.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, recipient, sender, and operator.
    /// - Multiple values for the gross deposit amount.
    /// - Operator fee zero and non-zero.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time lower than and equal to cliff time.
    /// - Cliff time lower than and equal to stop time.
    function testCreateWithRange(
        address funder,
        address recipient,
        uint128 grossDepositAmount,
        UD60x18 protocolFee,
        address operator,
        UD60x18 operatorFee,
        bool cancelable,
        Range memory range
    )
        external
        NetDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
        TokenContract
        TokenERC20Compliant
    {
        vm.assume(funder != address(0) && recipient != address(0) && operator != address(0));
        vm.assume(operator != address(linear));
        vm.assume(grossDepositAmount != 0);
        vm.assume(range.start <= range.cliff && range.cliff <= range.stop);
        protocolFee = bound(protocolFee, 0, MAX_FEE);
        operatorFee = bound(operatorFee, 0, MAX_FEE);

        // Make the fuzzed funder the caller in this test.
        changePrank(funder);

        // Mint enough tokens to the funder.
        deal({ token: defaultArgs.createWithRange.token, to: funder, give: grossDepositAmount });

        // Approve the SablierV2Linear contract to transfer the tokens from the funder.
        IERC20(defaultArgs.createWithRange.token).approve({ spender: address(linear), value: UINT256_MAX });

        // Load the stream id.
        uint256 streamId = linear.nextStreamId();

        // Calculate the operator fee amount and the net deposit amount.
        uint128 protocolFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(DEFAULT_PROTOCOL_FEE)));
        uint128 operatorFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(operatorFee)));
        uint128 netDepositAmount = grossDepositAmount - protocolFeeAmount - operatorFeeAmount;

        // Expect the tokens to be transferred from the funder to the SablierV2Linear contract.
        vm.expectCall(
            defaultArgs.createWithRange.token,
            abi.encodeCall(IERC20.transferFrom, (funder, address(linear), netDepositAmount))
        );

        // Expect the operator fee to be paid to the operator, if the fee amount is not zero.
        if (operatorFeeAmount > 0) {
            vm.expectCall(
                defaultArgs.createWithRange.token,
                abi.encodeCall(IERC20.transferFrom, (funder, operator, operatorFeeAmount))
            );
        }

        // Create the stream.
        linear.createWithRange(
            defaultArgs.createWithRange.sender,
            recipient,
            grossDepositAmount,
            operator,
            operatorFee,
            defaultArgs.createWithRange.token,
            cancelable,
            range
        );

        // Assert that the stream was created.
        LinearStream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.amounts, Amounts({ deposit: netDepositAmount, withdrawn: 0 }));
        assertEq(actualStream.isCancelable, cancelable);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.range, range);
        assertEq(actualStream.token, defaultStream.token);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = linear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = linear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }

    /// @dev it should record the protocol fee.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Multiple values for the gross deposit amount.
    /// - Protocol fee zero and non-zero.
    function testCreateWithRange__ProtocolFee(
        uint128 grossDepositAmount,
        UD60x18 protocolFee
    )
        external
        NetDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
        TokenContract
        TokenERC20Compliant
    {
        vm.assume(grossDepositAmount != 0);
        protocolFee = bound(protocolFee, 0, MAX_FEE);

        // Set the fuzzed protocol fee.
        changePrank(users.owner);
        comptroller.setProtocolFee(defaultArgs.createWithRange.token, protocolFee);

        // Make the sender the funder in this test.
        address funder = defaultArgs.createWithRange.sender;

        // Make the funder the caller in the rest of this test.
        changePrank(funder);

        // Mint enough tokens to the funder.
        deal({ token: defaultArgs.createWithRange.token, to: funder, give: grossDepositAmount });

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = linear.getProtocolRevenues(defaultArgs.createWithRange.token);

        // Create the stream with the fuzzed gross deposit amount.
        createDefaultStreamWithGrossDepositAmount(grossDepositAmount);

        // Calculate the protocol fee amount.
        uint128 protocolFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(protocolFee)));

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = linear.getProtocolRevenues(defaultArgs.createWithRange.token);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + protocolFeeAmount;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);
    }

    /// @dev it should emit a CreateLinearStream event.
    function testCreateWithRange__Event()
        external
        NetDepositAmountNotZero
        StartTimeLessThanOrEqualToCliffTime
        CliffLessThanOrEqualToStopTime
        TokenContract
        TokenERC20Compliant
    {
        uint256 streamId = linear.nextStreamId();
        address funder = defaultArgs.createWithRange.sender;
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
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.range
        );
        createDefaultStream();
    }
}
