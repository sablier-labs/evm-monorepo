// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Events } from "src/libraries/Events.sol";
import { DataTypes } from "src/types/DataTypes.sol";

import { IntegrationTest } from "../IntegrationTest.t.sol";

abstract contract CreateWithMilestones__Test is IntegrationTest {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(address token_, address holder_) IntegrationTest(token_, holder_) {}

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        // Approve the SablierV2Pro contract to transfer the token holder's tokens.
        // We use a low-level call to ignore reverts because the token can have the missing return value bug.
        (bool success, ) = token.call(abi.encodeCall(IERC20.approve, (address(pro), UINT256_MAX)));
        success;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev it should perform the ERC-20 transfers, emit a CreateProStream event, create the stream, record the
    /// protocol fee, bump the next stream id, and mint the NFT.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, recipient, sender, and operator.
    /// - Operator fee zero and non-zero.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time equal and not equal to the first segment milestone.
    function testCreateWithMilestones(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        address operator,
        UD60x18 operatorFee,
        bool cancelable,
        uint40 startTime
    ) external {
        vm.assume(sender != address(0) && recipient != address(0) && operator != address(0));
        vm.assume(operator != address(pro));
        vm.assume(grossDepositAmount != 0 && grossDepositAmount <= holderBalance);
        operatorFee = bound(operatorFee, 0, MAX_FEE);
        startTime = boundUint40(startTime, 0, DEFAULT_SEGMENT_MILESTONES[0]);

        // Load the current token balances.
        uint256 initialProBalance = IERC20(token).balanceOf(address(pro));
        uint256 initialHolderBalance = IERC20(token).balanceOf(holder);
        uint256 initialOperatorBalance = IERC20(token).balanceOf(operator);

        // Calculate the fee amounts and the net deposit amount.
        uint128 operatorFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(operatorFee)));
        uint128 netDepositAmount = grossDepositAmount - operatorFeeAmount;

        // Calculate the segment amounts.
        uint128[] memory segmentAmounts = calculateSegmentAmounts(netDepositAmount);

        // Expect an event to be emitted.
        uint256 streamId = pro.nextStreamId();
        uint128 protocolFeeAmount = 0;
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateProStream(
            streamId,
            holder,
            sender,
            recipient,
            netDepositAmount,
            segmentAmounts,
            DEFAULT_SEGMENT_EXPONENTS,
            protocolFeeAmount,
            operator,
            operatorFeeAmount,
            token,
            cancelable,
            startTime,
            DEFAULT_SEGMENT_MILESTONES
        );

        // Create the stream.
        pro.createWithMilestones(
            sender,
            recipient,
            grossDepositAmount,
            segmentAmounts,
            DEFAULT_SEGMENT_EXPONENTS,
            operator,
            operatorFee,
            token,
            cancelable,
            startTime,
            DEFAULT_SEGMENT_MILESTONES
        );

        // Assert that the stream was created.
        DataTypes.ProStream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.depositAmount, netDepositAmount);
        assertEq(actualStream.isCancelable, cancelable);
        assertEq(actualStream.isEntity, true);
        assertEq(actualStream.sender, sender);
        assertEqUint128Array(actualStream.segmentAmounts, segmentAmounts);
        assertEq(actualStream.segmentExponents, DEFAULT_SEGMENT_EXPONENTS);
        assertEqUint40Array(actualStream.segmentMilestones, DEFAULT_SEGMENT_MILESTONES);
        assertEq(actualStream.startTime, startTime);
        assertEq(actualStream.stopTime, DEFAULT_STOP_TIME);
        assertEq(actualStream.token, token);
        assertEq(actualStream.withdrawnAmount, 0);

        // Assert that the SablierV2Pro contract's balance was updated.
        uint256 actualProBalance = IERC20(token).balanceOf(address(pro));
        uint256 expectedProBalance = initialProBalance + netDepositAmount;
        assertEq(actualProBalance, expectedProBalance);

        // Assert that the holder's balance was updated.
        uint256 actualHolderBalance = IERC20(token).balanceOf(holder);
        uint256 expectedHolderBalance = initialHolderBalance - grossDepositAmount;
        assertEq(actualHolderBalance, expectedHolderBalance);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the operator's balance was updated.
        uint256 actualOperatorBalance = IERC20(token).balanceOf(operator);
        uint256 expectedOperatorBalance = initialOperatorBalance + operatorFeeAmount;
        assertEq(actualOperatorBalance, expectedOperatorBalance);

        // Assert that the NFT was minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }
}
