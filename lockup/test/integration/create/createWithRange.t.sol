// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Amounts, LinearStream, Segment, Range } from "src/types/Structs.sol";
import { Events } from "src/libraries/Events.sol";

import { IntegrationTest } from "../IntegrationTest.t.sol";

abstract contract CreateWithRange__Test is IntegrationTest {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(address token_, address holder_) IntegrationTest(token_, holder_) {}

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        IntegrationTest.setUp();

        // Approve the SablierV2Linear contract to transfer the token holder's tokens.
        // We use a low-level call to ignore reverts because the token can have the missing return value bug.
        (bool success, ) = token.call(abi.encodeCall(IERC20.approve, (address(linear), UINT256_MAX)));
        success;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    struct Args {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        address operator;
        UD60x18 operatorFee;
        bool cancelable;
        Range range;
    }

    struct Vars {
        uint256 initialContractBalance;
        uint256 initialHolderBalance;
        uint256 initialOperatorBalance;
        uint128 operatorFeeAmount;
        uint128 netDepositAmount;
        uint256 streamId;
        uint256 actualNextStreamId;
        uint256 expectedNextStreamId;
        address actualNFTOwner;
        address expectedNFTOwner;
        uint256 actualContractBalance;
        uint256 expectedContractBalance;
        uint256 actualHolderBalance;
        uint256 expectedHolderBalance;
        uint256 actualOperatorBalance;
        uint256 expectedOperatorBalance;
    }

    /// @dev it should perform the ERC-20 transfers, emit a CreateLinearStream event, create the stream, record the
    /// protocol fee, bump the next stream id, and mint the NFT.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, recipient, sender, and operator.
    /// - Multiple values for the gross deposit amount.
    /// - Operator fee zero and non-zero.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time lower than and equal to cliff time.
    /// - Cliff time lower than and equal to stop time
    function testCreateWithRange(Args memory args) external {
        vm.assume(args.sender != address(0) && args.recipient != address(0) && args.operator != address(0));
        vm.assume(args.operator != holder && args.operator != address(linear));
        vm.assume(args.grossDepositAmount != 0 && args.grossDepositAmount <= holderBalance);
        vm.assume(args.range.start <= args.range.cliff && args.range.cliff <= args.range.stop);
        args.operatorFee = bound(args.operatorFee, 0, MAX_FEE);

        // Load the current token balances.
        Vars memory vars;
        vars.initialContractBalance = IERC20(token).balanceOf(address(linear));
        vars.initialHolderBalance = IERC20(token).balanceOf(holder);
        vars.initialOperatorBalance = IERC20(token).balanceOf(args.operator);

        // Calculate the fee amounts and the net deposit amount.
        vars.operatorFeeAmount = uint128(UD60x18.unwrap(ud(args.grossDepositAmount).mul(args.operatorFee)));
        vars.netDepositAmount = args.grossDepositAmount - vars.operatorFeeAmount;

        // Expect an event to be emitted.
        vars.streamId = linear.nextStreamId();
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLinearStream(
            vars.streamId,
            holder,
            args.sender,
            args.recipient,
            vars.netDepositAmount,
            0,
            args.operator,
            vars.operatorFeeAmount,
            token,
            args.cancelable,
            args.range
        );

        // Create the stream.
        linear.createWithRange(
            args.sender,
            args.recipient,
            args.grossDepositAmount,
            args.operator,
            args.operatorFee,
            token,
            args.cancelable,
            args.range
        );

        // Assert that the stream was created.
        LinearStream memory actualStream = linear.getStream(vars.streamId);
        assertEq(actualStream.amounts, Amounts({ deposit: vars.netDepositAmount, withdrawn: 0 }));
        assertEq(actualStream.isCancelable, args.cancelable);
        assertEq(actualStream.isEntity, true);
        assertEq(actualStream.sender, args.sender);
        assertEq(actualStream.range, args.range);
        assertEq(actualStream.token, token);

        // Assert that the next stream id was bumped.
        vars.actualNextStreamId = linear.nextStreamId();
        vars.expectedNextStreamId = vars.streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId);

        // Assert that the NFT was minted.
        vars.actualNFTOwner = linear.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = args.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner);

        // Assert that the contract's balance was updated.
        vars.actualContractBalance = IERC20(token).balanceOf(address(linear));
        vars.expectedContractBalance = vars.initialContractBalance + vars.netDepositAmount;
        assertEq(vars.actualContractBalance, vars.expectedContractBalance);

        // Assert that the holder's balance was updated.
        vars.actualHolderBalance = IERC20(token).balanceOf(holder);
        vars.expectedHolderBalance = vars.initialHolderBalance - args.grossDepositAmount;
        assertEq(vars.actualHolderBalance, vars.expectedHolderBalance);

        // Assert that the operator's balance was updated.
        vars.actualOperatorBalance = IERC20(token).balanceOf(args.operator);
        vars.expectedOperatorBalance = vars.initialOperatorBalance + vars.operatorFeeAmount;
        assertEq(vars.actualOperatorBalance, vars.expectedOperatorBalance);
    }
}
