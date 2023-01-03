// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Amounts, LinearStream, Range } from "src/types/Structs.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract CreateWithDuration__LinearTest is LinearTest {
    /// @dev it should revert due to the start time being greater than the cliff time.
    function testCannotCreateWithDuration__CliffDurationCalculationOverflows(uint40 cliffDuration) external {
        uint40 startTime = getBlockTimestamp();
        cliffDuration = boundUint40(cliffDuration, UINT40_MAX - startTime + 1, UINT40_MAX);

        // Calculate the stop time. Needs to be "unchecked" to avoid an overflow.
        uint40 cliffTime;
        unchecked {
            cliffTime = startTime + cliffDuration;
        }

        // Expect an error.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Linear__StartTimeGreaterThanCliffTime.selector, startTime, cliffTime)
        );

        // Set the total duration to be the same as the cliff duration.
        uint40 totalDuration = cliffDuration;

        // Create the stream.
        linear.createWithDuration(
            defaultArgs.createWithDuration.sender,
            defaultArgs.createWithDuration.recipient,
            defaultArgs.createWithDuration.grossDepositAmount,
            defaultArgs.createWithDuration.operator,
            defaultArgs.createWithDuration.operatorFee,
            defaultArgs.createWithDuration.token,
            defaultArgs.createWithDuration.cancelable,
            cliffDuration,
            totalDuration
        );
    }

    modifier CliffDurationCalculationDoesNotOverflow() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithDuration__TotalDurationCalculationOverflows(
        uint40 cliffDuration,
        uint40 totalDuration
    ) external CliffDurationCalculationDoesNotOverflow {
        uint40 startTime = getBlockTimestamp();
        cliffDuration = boundUint40(cliffDuration, 0, UINT40_MAX - startTime);
        totalDuration = boundUint40(totalDuration, UINT40_MAX - startTime + 1, UINT40_MAX);

        // Calculate the cliff time and the stop time. Needs to be "unchecked" to avoid an overflow.
        uint40 cliffTime;
        uint40 stopTime;
        unchecked {
            cliffTime = startTime + cliffDuration;
            stopTime = startTime + totalDuration;
        }

        // Expect an error.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Linear__CliffTimeGreaterThanStopTime.selector, cliffTime, stopTime)
        );

        // Create the stream.
        linear.createWithDuration(
            defaultArgs.createWithDuration.sender,
            defaultArgs.createWithDuration.recipient,
            defaultArgs.createWithDuration.grossDepositAmount,
            defaultArgs.createWithDuration.operator,
            defaultArgs.createWithDuration.operatorFee,
            defaultArgs.createWithDuration.token,
            defaultArgs.createWithDuration.cancelable,
            cliffDuration,
            totalDuration
        );
    }

    modifier TotalDurationCalculationDoesNotOverflow() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, and mint the NFT.
    function testCreateWithDuration(
        uint40 cliffDuration,
        uint40 totalDuration
    ) external CliffDurationCalculationDoesNotOverflow TotalDurationCalculationDoesNotOverflow {
        totalDuration = boundUint40(totalDuration, 0, UINT40_MAX - getBlockTimestamp());
        vm.assume(cliffDuration <= totalDuration);

        // Make the sender the funder in this test.
        address funder = defaultArgs.createWithDuration.sender;

        // Expect the tokens to be transferred from the funder to the SablierV2Linear contract.
        vm.expectCall(
            address(defaultArgs.createWithDuration.token),
            abi.encodeCall(IERC20.transferFrom, (funder, address(linear), DEFAULT_NET_DEPOSIT_AMOUNT))
        );

        // Expect the operator fee to be paid to the operator, if the amount is not zero.
        vm.expectCall(
            address(defaultArgs.createWithDuration.token),
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, defaultArgs.createWithDuration.operator, DEFAULT_OPERATOR_FEE_AMOUNT)
            )
        );

        // Calculate the start time, cliff time and the stop time.
        Range memory range = Range({
            start: getBlockTimestamp(),
            cliff: getBlockTimestamp() + cliffDuration,
            stop: getBlockTimestamp() + totalDuration
        });

        // Create the stream.
        uint256 streamId = linear.createWithDuration(
            defaultArgs.createWithDuration.sender,
            defaultArgs.createWithDuration.recipient,
            defaultArgs.createWithDuration.grossDepositAmount,
            defaultArgs.createWithDuration.operator,
            defaultArgs.createWithDuration.operatorFee,
            defaultArgs.createWithDuration.token,
            defaultArgs.createWithDuration.cancelable,
            cliffDuration,
            totalDuration
        );

        // Assert that the stream was created.
        LinearStream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(actualStream.isCancelable, defaultStream.isCancelable);
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
        address expectedNFTOwner = defaultArgs.createWithDuration.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }

    /// @dev it should record the protocol fee.
    function testCreateWithDuration__ProtocolFee()
        external
        CliffDurationCalculationDoesNotOverflow
        TotalDurationCalculationDoesNotOverflow
    {
        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = linear.getProtocolRevenues(defaultArgs.createWithRange.token);

        // Create the default stream.
        createDefaultStream();

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = linear.getProtocolRevenues(defaultArgs.createWithDuration.token);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + DEFAULT_PROTOCOL_FEE_AMOUNT;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);
    }

    /// @dev it should emit a CreateLinearStream event.
    function testCreateWithDuration__Event()
        external
        CliffDurationCalculationDoesNotOverflow
        TotalDurationCalculationDoesNotOverflow
    {
        uint256 streamId = linear.nextStreamId();
        address funder = defaultArgs.createWithDuration.sender;
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLinearStream(
            streamId,
            funder,
            defaultArgs.createWithDuration.sender,
            defaultArgs.createWithDuration.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            DEFAULT_PROTOCOL_FEE_AMOUNT,
            defaultArgs.createWithDuration.operator,
            DEFAULT_OPERATOR_FEE_AMOUNT,
            defaultArgs.createWithDuration.token,
            defaultArgs.createWithDuration.cancelable,
            DEFAULT_RANGE
        );
        createDefaultStream();
    }
}
