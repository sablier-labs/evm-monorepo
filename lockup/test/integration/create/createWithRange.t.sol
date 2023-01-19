// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Events } from "src/libraries/Events.sol";
import { Status } from "src/types/Enums.sol";
import { Broker, LockupAmounts, CreateLockupAmounts, LockupLinearStream, Segment, Range } from "src/types/Structs.sol";

import { IntegrationTest } from "../IntegrationTest.t.sol";

abstract contract CreateWithRange_Test is IntegrationTest {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset_, address holder_) IntegrationTest(asset_, holder_) {}

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        IntegrationTest.setUp();

        // Approve the {SablierV2LockupLinear} contract to transfer the asset holder's assets.
        // We use a low-level call to ignore reverts because the asset can have the missing return value bug.
        (bool success, ) = address(asset).call(abi.encodeCall(IERC20.approve, (address(linear), UINT256_MAX)));
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
        uint256[] initialBalances;
        uint256 initialLinearBalance;
        uint256 initialBrokerBalance;
        uint128 brokerFeeAmount;
        uint128 netDepositAmount;
        uint256 streamId;
        uint256 actualNextStreamId;
        uint256 expectedNextStreamId;
        address actualNFTOwner;
        address expectedNFTOwner;
        uint256[] actualBalances;
        uint256 actualLinearBalance;
        uint256 expectedLinearBalance;
        uint256 actualHolderBalance;
        uint256 expectedHolderBalance;
        uint256 actualBrokerBalance;
        uint256 expectedBrokerBalance;
    }

    /// @dev it should perform the ERC-20 transfers, emit a CreateLockupLinearStream event, create the stream, record
    /// the protocol fee, bump the next stream id, and mint the NFT.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, recipient, sender, and broker.
    /// - Multiple values for the gross deposit amount.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time lower than and equal to cliff time.
    /// - Cliff time lower than and equal to stop time
    /// - Multiple values for the broker fee, including zero.
    function testForkFuzz_testCreateWithRange(Params memory params) external {
        vm.assume(params.sender != address(0) && params.recipient != address(0) && params.broker.addr != address(0));
        vm.assume(params.broker.addr != holder && params.broker.addr != address(linear));
        vm.assume(params.grossDepositAmount != 0 && params.grossDepositAmount <= initialHolderBalance);
        vm.assume(params.range.start <= params.range.cliff && params.range.cliff <= params.range.stop);
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);

        // Load the initial asset balances.
        Vars memory vars;
        vars.initialBalances = getTokenBalances(
            address(asset),
            Solarray.addresses(address(linear), params.broker.addr)
        );
        vars.initialLinearBalance = vars.initialBalances[0];
        vars.initialBrokerBalance = vars.initialBalances[1];

        // Calculate the fee amounts and the net deposit amount.
        vars.brokerFeeAmount = ud(params.grossDepositAmount).mul(params.broker.fee).intoUint128();
        vars.netDepositAmount = params.grossDepositAmount - vars.brokerFeeAmount;

        // Expect an event to be emitted.
        vars.streamId = linear.nextStreamId();
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLockupLinearStream({
            streamId: vars.streamId,
            funder: holder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: CreateLockupAmounts({
                netDeposit: vars.netDepositAmount,
                protocolFee: 0,
                brokerFee: vars.brokerFeeAmount
            }),
            asset: asset,
            cancelable: params.cancelable,
            range: params.range,
            broker: params.broker.addr
        });

        // Create the stream.
        linear.createWithRange(
            params.sender,
            params.recipient,
            params.grossDepositAmount,
            asset,
            params.cancelable,
            params.range,
            params.broker
        );

        // Assert that the stream was created.
        LockupLinearStream memory actualStream = linear.getStream(vars.streamId);
        assertEq(actualStream.amounts, LockupAmounts({ deposit: vars.netDepositAmount, withdrawn: 0 }));
        assertEq(actualStream.asset, asset);
        assertEq(actualStream.isCancelable, params.cancelable);
        assertEq(actualStream.range, params.range);
        assertEq(actualStream.sender, params.sender);
        assertEq(actualStream.status, Status.ACTIVE);

        // Assert that the next stream id was bumped.
        vars.actualNextStreamId = linear.nextStreamId();
        vars.expectedNextStreamId = vars.streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the NFT was minted.
        vars.actualNFTOwner = linear.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");

        // Load the actual asset balances.
        vars.actualBalances = getTokenBalances(
            address(asset),
            Solarray.addresses(address(linear), holder, params.broker.addr)
        );
        vars.actualLinearBalance = vars.actualBalances[0];
        vars.actualHolderBalance = vars.actualBalances[1];
        vars.actualBrokerBalance = vars.actualBalances[2];

        // Assert that the contract's balance was updated.
        vars.expectedLinearBalance = vars.initialLinearBalance + vars.netDepositAmount;
        assertEq(vars.actualLinearBalance, vars.expectedLinearBalance, "contract balance");

        // Assert that the holder's balance was updated.
        vars.expectedHolderBalance = initialHolderBalance - params.grossDepositAmount;
        assertEq(vars.actualHolderBalance, vars.expectedHolderBalance, "holder balance");

        // Assert that the broker's balance was updated.
        vars.expectedBrokerBalance = vars.initialBrokerBalance + vars.brokerFeeAmount;
        assertEq(vars.actualBrokerBalance, vars.expectedBrokerBalance, "broker balance");
    }
}
