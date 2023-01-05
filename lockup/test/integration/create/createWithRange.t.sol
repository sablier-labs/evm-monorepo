// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Amounts, Broker, CreateAmounts, LinearStream, Segment, Range } from "src/types/Structs.sol";
import { Events } from "src/libraries/Events.sol";

import { IntegrationTest } from "../IntegrationTest.t.sol";

abstract contract CreateWithRange__Test is IntegrationTest {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 token_, address holder_) IntegrationTest(token_, holder_) {}

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        IntegrationTest.setUp();

        // Approve the SablierV2Linear contract to transfer the token holder's tokens.
        // We use a low-level call to ignore reverts because the token can have the missing return value bug.
        (bool success, ) = address(token).call(abi.encodeCall(IERC20.approve, (address(linear), UINT256_MAX)));
        success;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    struct Params {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        bool cancelable;
        Range range;
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

    /// @dev it should perform the ERC-20 transfers, emit a CreateLinearStream event, create the stream, record the
    /// protocol fee, bump the next stream id, and mint the NFT.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, recipient, sender, and broker.
    /// - Multiple values for the gross deposit amount.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time lower than and equal to cliff time.
    /// - Cliff time lower than and equal to stop time
    /// - Broker fee zero and non-zero.
    function testCreateWithRange(Params memory params) external {
        vm.assume(params.sender != address(0) && params.recipient != address(0) && params.broker.addr != address(0));
        vm.assume(params.broker.addr != holder && params.broker.addr != address(linear));
        vm.assume(params.grossDepositAmount != 0 && params.grossDepositAmount <= holderBalance);
        vm.assume(params.range.start <= params.range.cliff && params.range.cliff <= params.range.stop);
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);

        // Load the current token balances.
        Vars memory vars;
        vars.initialContractBalance = IERC20(token).balanceOf(address(linear));
        vars.initialHolderBalance = IERC20(token).balanceOf(holder);
        vars.initialBrokerBalance = IERC20(token).balanceOf(params.broker.addr);

        // Calculate the fee amounts and the net deposit amount.
        vars.brokerFeeAmount = uint128(UD60x18.unwrap(ud(params.grossDepositAmount).mul(params.broker.fee)));
        vars.netDepositAmount = params.grossDepositAmount - vars.brokerFeeAmount;

        // Expect an event to be emitted.
        vars.streamId = linear.nextStreamId();
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLinearStream({
            streamId: vars.streamId,
            funder: holder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: CreateAmounts({
                netDeposit: vars.netDepositAmount,
                protocolFee: 0,
                brokerFee: vars.brokerFeeAmount
            }),
            token: token,
            cancelable: params.cancelable,
            range: params.range,
            broker: params.broker.addr
        });

        // Create the stream.
        linear.createWithRange(
            params.sender,
            params.recipient,
            params.grossDepositAmount,
            token,
            params.cancelable,
            params.range,
            params.broker
        );

        // Assert that the stream was created.
        LinearStream memory actualStream = linear.getStream(vars.streamId);
        assertEq(actualStream.amounts, Amounts({ deposit: vars.netDepositAmount, withdrawn: 0 }));
        assertEq(actualStream.isCancelable, params.cancelable);
        assertEq(actualStream.isEntity, true);
        assertEq(actualStream.sender, params.sender);
        assertEq(actualStream.range, params.range);
        assertEq(actualStream.token, token);

        // Assert that the next stream id was bumped.
        vars.actualNextStreamId = linear.nextStreamId();
        vars.expectedNextStreamId = vars.streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the NFT was minted.
        vars.actualNFTOwner = linear.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");

        // Assert that the contract's balance was updated.
        vars.actualContractBalance = IERC20(token).balanceOf(address(linear));
        vars.expectedContractBalance = vars.initialContractBalance + vars.netDepositAmount;
        assertEq(vars.actualContractBalance, vars.expectedContractBalance, "contract balance");

        // Assert that the holder's balance was updated.
        vars.actualHolderBalance = IERC20(token).balanceOf(holder);
        vars.expectedHolderBalance = vars.initialHolderBalance - params.grossDepositAmount;
        assertEq(vars.actualHolderBalance, vars.expectedHolderBalance, "holder balance");

        // Assert that the broker's balance was updated.
        vars.actualBrokerBalance = IERC20(token).balanceOf(params.broker.addr);
        vars.expectedBrokerBalance = vars.initialBrokerBalance + vars.brokerFeeAmount;
        assertEq(vars.actualBrokerBalance, vars.expectedBrokerBalance, "broker balance");
    }
}
