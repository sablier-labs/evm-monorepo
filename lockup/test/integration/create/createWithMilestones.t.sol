// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Amounts, Broker, CreateAmounts, ProStream, Segment } from "src/types/Structs.sol";
import { Events } from "src/libraries/Events.sol";

import { IntegrationTest } from "../IntegrationTest.t.sol";

abstract contract CreateWithMilestones__Test is IntegrationTest {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 token_, address holder_) IntegrationTest(token_, holder_) {}

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        IntegrationTest.setUp();

        // Approve the SablierV2Pro contract to transfer the token holder's tokens.
        // We use a low-level call to ignore reverts because the token can have the missing return value bug.
        (bool success, ) = address(token).call(abi.encodeCall(IERC20.approve, (address(pro), UINT256_MAX)));
        success;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    struct Args {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        bool cancelable;
        uint40 startTime;
        Broker broker;
    }

    struct Vars {
        uint256 initialContractBalance;
        uint256 initialHolderBalance;
        uint256 initialBrokerBalance;
        uint128 brokerFeeAmount;
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
        uint256 actualBrokerBalance;
        uint256 expectedBrokerBalance;
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
    function testCreateWithMilestones(Args memory args) external {
        vm.assume(args.sender != address(0) && args.recipient != address(0) && args.broker.addr != address(0));
        vm.assume(args.broker.addr != holder && args.broker.addr != address(pro));
        vm.assume(args.grossDepositAmount != 0 && args.grossDepositAmount <= holderBalance);
        args.broker.fee = bound(args.broker.fee, 0, DEFAULT_MAX_FEE);
        args.startTime = boundUint40(args.startTime, 0, DEFAULT_SEGMENTS[0].milestone);

        // Load the current token balances.
        Vars memory vars;
        vars.initialContractBalance = IERC20(token).balanceOf(address(pro));
        vars.initialHolderBalance = IERC20(token).balanceOf(holder);
        vars.initialBrokerBalance = IERC20(token).balanceOf(args.broker.addr);

        // Calculate the fee amounts and the net deposit amount.
        vars.brokerFeeAmount = uint128(UD60x18.unwrap(ud(args.grossDepositAmount).mul(args.broker.fee)));
        vars.netDepositAmount = args.grossDepositAmount - vars.brokerFeeAmount;

        // Adjust the segment amounts based on the fuzzed net deposit amount.
        Segment[] memory segments = DEFAULT_SEGMENTS;
        adjustSegmentAmounts(segments, vars.netDepositAmount);

        // Expect an event to be emitted.
        vars.streamId = pro.nextStreamId();
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateProStream({
            streamId: vars.streamId,
            funder: holder,
            sender: args.sender,
            recipient: args.recipient,
            amounts: CreateAmounts({
                netDeposit: vars.netDepositAmount,
                protocolFee: 0,
                brokerFee: vars.brokerFeeAmount
            }),
            segments: segments,
            token: token,
            cancelable: args.cancelable,
            startTime: args.startTime,
            broker: args.broker.addr
        });

        // Create the stream.
        pro.createWithMilestones(
            args.sender,
            args.recipient,
            args.grossDepositAmount,
            segments,
            token,
            args.cancelable,
            args.startTime,
            args.broker
        );

        // Assert that the stream was created.
        ProStream memory actualStream = pro.getStream(vars.streamId);
        assertEq(actualStream.amounts, Amounts({ deposit: vars.netDepositAmount, withdrawn: 0 }));
        assertEq(actualStream.isCancelable, args.cancelable);
        assertEq(actualStream.isEntity, true);
        assertEq(actualStream.segments, segments);
        assertEq(actualStream.sender, args.sender);
        assertEq(actualStream.startTime, args.startTime);
        assertEq(actualStream.token, token);

        // Assert that the next stream id was bumped.
        vars.actualNextStreamId = pro.nextStreamId();
        vars.expectedNextStreamId = vars.streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the NFT was minted.
        vars.actualNFTOwner = pro.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = args.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");

        // Assert that the contract's balance was updated.
        vars.actualContractBalance = IERC20(token).balanceOf(address(pro));
        vars.expectedContractBalance = vars.initialContractBalance + vars.netDepositAmount;
        assertEq(vars.actualContractBalance, vars.expectedContractBalance, "contract balance");

        // Assert that the holder's balance was updated.
        vars.actualHolderBalance = IERC20(token).balanceOf(holder);
        vars.expectedHolderBalance = vars.initialHolderBalance - args.grossDepositAmount;
        assertEq(vars.actualHolderBalance, vars.expectedHolderBalance, "holder balance");

        // Assert that the broker's balance was updated.
        vars.actualBrokerBalance = IERC20(token).balanceOf(args.broker.addr);
        vars.expectedBrokerBalance = vars.initialBrokerBalance + vars.brokerFeeAmount;
        assertEq(vars.actualBrokerBalance, vars.expectedBrokerBalance, "broker balance");
    }
}
