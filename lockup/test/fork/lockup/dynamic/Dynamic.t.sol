// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Broker, Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { Fork_Test } from "../../Fork.t.sol";

abstract contract Dynamic_Fork_Test is Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset_, address holder_) Fork_Test(asset_, holder_) { }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fork_Test.setUp();

        // Approve {SablierV2LockupDynamic} to transfer the holder's assets.
        // We use a low-level call to ignore reverts because the asset can have the missing return value bug.
        (bool success,) = address(asset).call(abi.encodeCall(IERC20.approve, (address(dynamic), UINT256_MAX)));
        success;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    struct Params {
        Broker broker;
        UD60x18 protocolFee;
        address recipient;
        address sender;
        uint40 startTime;
        uint40 warpTimestamp;
        LockupDynamic.Segment[] segments;
        uint128 withdrawAmount;
    }

    struct Vars {
        // Generic vars
        address actualNFTOwner;
        uint256 actualDynamicContractBalance;
        uint256 actualRecipientBalance;
        Lockup.Status actualStatus;
        uint256[] balances;
        address expectedNFTOwner;
        uint256 expectedDynamicContractBalance;
        uint256 expectedRecipientBalance;
        Lockup.Status expectedStatus;
        uint256 initialDynamicContractBalance;
        uint256 initialRecipientBalance;
        LockupDynamic.Range range;
        uint256 streamId;
        // Create vars
        uint256 actualBrokerBalance;
        uint256 actualHolderBalance;
        uint256 actualNextStreamId;
        uint256 actualProtocolRevenues;
        Lockup.CreateAmounts createAmounts;
        uint256 expectedBrokerBalance;
        uint256 expectedHolderBalance;
        uint256 expectedProtocolRevenues;
        uint256 expectedNextStreamId;
        uint256 initialBrokerBalance;
        uint256 initialProtocolRevenues;
        uint128 totalAmount;
        // Withdraw vars
        uint128 actualWithdrawnAmount;
        uint128 expectedWithdrawnAmount;
        uint128 withdrawableAmount;
        // Cancel vars
        uint256 actualSenderBalance;
        uint256 expectedSenderBalance;
        uint256 initialSenderBalance;
        uint128 recipientAmount;
        uint128 senderAmount;
    }

    /// @dev Checklist:
    ///
    /// - It should perform all expected ERC-20 transfers.
    /// - It should create the stream.
    /// - It should bump the next stream id.
    /// - It should record the protocol fee.
    /// - It should mint the NFT.
    /// - It should emit a {CreateLockupDynamicStream} event.
    /// - It may make a withdrawal.
    /// - It may update the withdrawn amounts.
    /// - It may emit a {WithdrawFromLockupStream} event.
    /// - It may cancel the stream
    /// - It may emit a {CancelLockupStream} event
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Multiple values for the funder, recipient, sender, and broker
    /// - Multiple values for the total amount
    /// - Start time in the past, present and future
    /// - Start time equal and not equal to the first segment milestone
    /// - Multiple values for the broker fee, including zero
    /// - Multiple values for the protocol fee, including zero
    /// - Multiple values for the withdraw amount, including zero
    function testForkFuzz_Dynamic_CreateWithdrawCancel(Params memory params) external {
        checkUsers(params.sender, params.recipient, params.broker.account, address(dynamic));
        vm.assume(params.segments.length != 0);
        params.broker.fee = bound(params.broker.fee, 0, MAX_FEE);
        params.protocolFee = bound(params.protocolFee, 0, MAX_FEE);
        params.startTime = boundUint40(params.startTime, 0, DEFAULT_START_TIME);

        // Fuzz the segment milestones.
        fuzzSegmentMilestones(params.segments, params.startTime);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        Vars memory vars;
        (vars.totalAmount, vars.createAmounts) = fuzzSegmentAmountsAndCalculateCreateAmounts({
            upperBound: uint128(initialHolderBalance),
            segments: params.segments,
            protocolFee: params.protocolFee,
            brokerFee: params.broker.fee
        });

        // Set the fuzzed protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: asset, newProtocolFee: params.protocolFee });

        // Make the holder the caller in the rest of the test.
        changePrank(holder);

        /*//////////////////////////////////////////////////////////////////////////
                                            CREATE
        //////////////////////////////////////////////////////////////////////////*/

        // Load the pre-create protocol revenues.
        vars.initialProtocolRevenues = dynamic.protocolRevenues(asset);

        // Load the pre-create asset balances.
        vars.balances = getTokenBalances(address(asset), Solarray.addresses(address(dynamic), params.broker.account));
        vars.initialDynamicContractBalance = vars.balances[0];
        vars.initialBrokerBalance = vars.balances[1];

        // Expect a {CreateLockupDynamicStream} event to be emitted.
        vars.streamId = dynamic.nextStreamId();
        vm.expectEmit({ emitter: address(dynamic) });
        vars.range =
            LockupDynamic.Range({ start: params.startTime, end: params.segments[params.segments.length - 1].milestone });
        emit CreateLockupDynamicStream({
            streamId: vars.streamId,
            funder: holder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: vars.createAmounts,
            asset: asset,
            cancelable: true,
            segments: params.segments,
            range: vars.range,
            broker: params.broker.account
        });

        // Create the stream.
        dynamic.createWithMilestones(
            LockupDynamic.CreateWithMilestones({
                sender: params.sender,
                recipient: params.recipient,
                totalAmount: vars.totalAmount,
                asset: asset,
                cancelable: true,
                segments: params.segments,
                startTime: params.startTime,
                broker: params.broker
            })
        );

        // Assert that the stream has been created.
        LockupDynamic.Stream memory actualStream = dynamic.getStream(vars.streamId);
        assertEq(actualStream.amounts, Lockup.Amounts(vars.createAmounts.deposit, 0, 0));
        assertEq(actualStream.asset, asset, "asset");
        assertEq(actualStream.endTime, vars.range.end, "endTime");
        assertEq(actualStream.isCancelable, true, "isCancelable");
        assertEq(actualStream.segments, params.segments);
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.startTime, params.startTime, "startTime");
        assertEq(actualStream.status, Lockup.Status.ACTIVE);

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = dynamic.nextStreamId();
        vars.expectedNextStreamId = vars.streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = dynamic.protocolRevenues(asset);
        vars.expectedProtocolRevenues = vars.initialProtocolRevenues + vars.createAmounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = dynamic.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");

        // Load the post-create asset balances.
        vars.balances =
            getTokenBalances(address(asset), Solarray.addresses(address(dynamic), holder, params.broker.account));
        vars.actualDynamicContractBalance = vars.balances[0];
        vars.actualHolderBalance = vars.balances[1];
        vars.actualBrokerBalance = vars.balances[2];

        // Assert that the dynamic contract's balance has been updated.
        vars.expectedDynamicContractBalance =
            vars.initialDynamicContractBalance + vars.createAmounts.deposit + vars.createAmounts.protocolFee;
        assertEq(
            vars.actualDynamicContractBalance,
            vars.expectedDynamicContractBalance,
            "post-create dynamic contract balance"
        );

        // Assert that the holder's balance has been updated.
        vars.expectedHolderBalance = initialHolderBalance - vars.totalAmount;
        assertEq(vars.actualHolderBalance, vars.expectedHolderBalance, "post-create holder balance");

        // Assert that the broker's balance has been updated.
        vars.expectedBrokerBalance = vars.initialBrokerBalance + vars.createAmounts.brokerFee;
        assertEq(vars.actualBrokerBalance, vars.expectedBrokerBalance, "post-create broker balance");

        /*//////////////////////////////////////////////////////////////////////////
                                          WITHDRAW
        //////////////////////////////////////////////////////////////////////////*/

        // Warp into the future.
        params.warpTimestamp = boundUint40(params.warpTimestamp, vars.range.start, vars.range.end - 1);
        vm.warp({ timestamp: params.warpTimestamp });

        // Bound the withdraw amount.
        vars.withdrawableAmount = dynamic.withdrawableAmountOf(vars.streamId);
        params.withdrawAmount = boundUint128(params.withdrawAmount, 0, vars.withdrawableAmount);

        // Only run the withdraw tests if the withdraw amount is not zero.
        if (params.withdrawAmount > 0) {
            // Load the pre-withdraw asset balances.
            vars.initialDynamicContractBalance = vars.actualDynamicContractBalance;
            vars.initialRecipientBalance = asset.balanceOf(params.recipient);

            // Expect a {WithdrawFromLockupStream} event to be emitted.
            vm.expectEmit({ emitter: address(dynamic) });
            emit WithdrawFromLockupStream({
                streamId: vars.streamId,
                to: params.recipient,
                amount: params.withdrawAmount
            });

            // Make the withdrawal.
            changePrank({ msgSender: params.recipient });
            dynamic.withdraw({ streamId: vars.streamId, to: params.recipient, amount: params.withdrawAmount });

            // Assert that the withdrawn amount has been updated.
            vars.actualWithdrawnAmount = dynamic.getWithdrawnAmount(vars.streamId);
            vars.expectedWithdrawnAmount = params.withdrawAmount;
            assertEq(vars.actualWithdrawnAmount, vars.expectedWithdrawnAmount, "withdrawnAmount");

            // Load the post-withdraw asset balances.
            vars.balances = getTokenBalances(address(asset), Solarray.addresses(address(dynamic), params.recipient));
            vars.actualDynamicContractBalance = vars.balances[0];
            vars.actualRecipientBalance = vars.balances[1];

            // Assert that the contract's balance has been updated.
            vars.expectedDynamicContractBalance = vars.initialDynamicContractBalance - uint256(params.withdrawAmount);
            assertEq(
                vars.actualDynamicContractBalance,
                vars.expectedDynamicContractBalance,
                "post-withdraw dynamic contract balance"
            );

            // Assert that the recipient's balance has been updated.
            vars.expectedRecipientBalance = vars.initialRecipientBalance + uint256(params.withdrawAmount);
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-withdraw recipient balance");
        }

        /*//////////////////////////////////////////////////////////////////////////
                                          CANCEL
        //////////////////////////////////////////////////////////////////////////*/

        // Only run the cancel tests if the stream is not settled. A dynamic stream can settle even before the end time
        // is reached when the last segment amount is zero.
        if (!dynamic.isSettled(vars.streamId)) {
            // Load the pre-cancel asset balances.
            vars.balances =
                getTokenBalances(address(asset), Solarray.addresses(address(dynamic), params.sender, params.recipient));
            vars.initialDynamicContractBalance = vars.balances[0];
            vars.initialSenderBalance = vars.balances[1];
            vars.initialRecipientBalance = vars.balances[2];

            // Expect a {CancelLockupStream} event to be emitted.
            vm.expectEmit({ emitter: address(dynamic) });
            vars.senderAmount = dynamic.refundableAmountOf(vars.streamId);
            vars.recipientAmount = dynamic.withdrawableAmountOf(vars.streamId);
            emit CancelLockupStream(
                vars.streamId, params.sender, params.recipient, vars.senderAmount, vars.recipientAmount
            );

            // Cancel the stream.
            changePrank({ msgSender: params.sender });
            dynamic.cancel(vars.streamId);

            // Assert that the status has been updated.
            vars.actualStatus = dynamic.getStatus(vars.streamId);
            vars.expectedStatus = vars.recipientAmount > 0 ? Lockup.Status.CANCELED : Lockup.Status.DEPLETED;
            assertEq(vars.actualStatus, vars.expectedStatus, "status after cancel");

            // Assert that the NFT has not been burned.
            vars.actualNFTOwner = dynamic.ownerOf({ tokenId: vars.streamId });
            vars.expectedNFTOwner = params.recipient;
            assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner after cancel");

            // Load the post-cancel asset balances.
            vars.balances =
                getTokenBalances(address(asset), Solarray.addresses(address(dynamic), params.sender, params.recipient));
            vars.actualDynamicContractBalance = vars.balances[0];
            vars.actualSenderBalance = vars.balances[1];
            vars.actualRecipientBalance = vars.balances[2];

            // Assert that the contract's balance has been updated.
            vars.expectedDynamicContractBalance = vars.initialDynamicContractBalance - uint256(vars.senderAmount);
            assertEq(
                vars.actualDynamicContractBalance,
                vars.expectedDynamicContractBalance,
                "post-cancel dynamic contract balance"
            );

            // Assert that the sender's balance has been updated.
            vars.expectedSenderBalance = vars.initialSenderBalance + uint256(vars.senderAmount);
            assertEq(vars.actualSenderBalance, vars.expectedSenderBalance, "post-cancel sender balance");

            // Assert that the recipient's balance has stayed put.
            vars.expectedRecipientBalance = vars.initialRecipientBalance;
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-cancel recipient balance");
        }
    }
}
