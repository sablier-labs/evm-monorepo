// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract CreateWithDuration__Test is LinearTest {
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
        sablierV2Linear.createWithDuration(
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

    /// @dev When the total duration calculation overflows uint256, it should revert.
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
        sablierV2Linear.createWithDuration(
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

    /// @dev it should perform the ERC-20 transfers, emit a CreateLinearStream event, create the stream, bump the next
    /// stream id and mint the NFT.
    function testCreateWithDuration(
        uint40 cliffDuration,
        uint40 totalDuration
    ) external CliffDurationCalculationDoesNotOverflow TotalDurationCalculationDoesNotOverflow {
        totalDuration = boundUint40(totalDuration, 0, UINT40_MAX - getBlockTimestamp());
        vm.assume(cliffDuration <= totalDuration);

        // Expect the tokens to be transferred from the funder to the SablierV2Linear contract, and the operator fee
        // to be paid to the operator.
        address token = defaultArgs.createWithDuration.token;
        address funder = defaultArgs.createWithDuration.sender;
        vm.expectCall(
            token,
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, address(sablierV2Linear), defaultArgs.createWithDuration.grossDepositAmount)
            )
        );

        // Expect the the operator fee to be paid to the operator, if the fee amount is not zero.
        vm.expectCall(
            token,
            abi.encodeCall(IERC20.transfer, (defaultArgs.createWithDuration.operator, DEFAULT_OPERATOR_FEE_AMOUNT))
        );

        // Calculate the start time, cliff time and the stop time.
        uint40 startTime = getBlockTimestamp();
        uint40 cliffTime = startTime + cliffDuration;
        uint40 stopTime = startTime + totalDuration;

        // Expect an event to be emitted.
        uint256 streamId = sablierV2Linear.nextStreamId();
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
            token,
            defaultArgs.createWithDuration.cancelable,
            startTime,
            cliffTime,
            stopTime
        );

        // Create the stream.
        sablierV2Linear.createWithDuration(
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
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(streamId);
        assertEq(actualStream.cancelable, defaultStream.cancelable);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.depositAmount, defaultStream.depositAmount);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.startTime, startTime);
        assertEq(actualStream.stopTime, stopTime);
        assertEq(actualStream.token, token);
        assertEq(actualStream.withdrawnAmount, defaultStream.withdrawnAmount);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = sablierV2Linear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultArgs.createWithDuration.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }
}
