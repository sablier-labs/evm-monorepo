// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Broker, Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { Fork_Test } from "./Fork.t.sol";

abstract contract LockupDynamic_Fork_Test is Fork_Test {
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
        (bool success,) = address(asset).call(abi.encodeCall(IERC20.approve, (address(lockupDynamic), MAX_UINT256)));
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
        uint256 actualLockupDynamicBalance;
        uint256 actualRecipientBalance;
        Lockup.Status actualStatus;
        uint256[] balances;
        address expectedNFTOwner;
        uint256 expectedLockupDynamicBalance;
        uint256 expectedRecipientBalance;
        Lockup.Status expectedStatus;
        uint256 initialLockupDynamicBalance;
        uint256 initialRecipientBalance;
        bool isCancelable;
        bool isDepleted;
        bool isSettled;
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
    /// Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the funder, recipient, sender, and broker
    /// - Multiple values for the total amount
    /// - Start time in the past
    /// - Start time in the present
    /// - Start time in the future
    /// - Start time equal and not equal to the first segment milestone
    /// - Multiple values for the broker fee, including zero
    /// - Multiple values for the protocol fee, including zero
    /// - Multiple values for the withdraw amount, including zero
    /// - The whole gamut of stream statuses
    function testForkFuzz_LockupDynamic_CreateWithdrawCancel(Params memory params) external {
        checkUsers(params.sender, params.recipient, params.broker.account, address(lockupDynamic));
        vm.assume(params.segments.length != 0);
        params.broker.fee = _bound(params.broker.fee, 0, MAX_FEE);
        params.protocolFee = _bound(params.protocolFee, 0, MAX_FEE);
        params.startTime = boundUint40(params.startTime, 0, defaults.START_TIME());

        // Fuzz the segment milestones.
        fuzzSegmentMilestones(params.segments, params.startTime);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        Vars memory vars;
        (vars.totalAmount, vars.createAmounts) = fuzzDynamicStreamAmounts({
            upperBound: uint128(initialHolderBalance),
            segments: params.segments,
            protocolFee: params.protocolFee,
            brokerFee: params.broker.fee
        });

        // Set the fuzzed protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: asset, newProtocolFee: params.protocolFee });

        // Make the holder the caller.
        changePrank(holder);

        /*//////////////////////////////////////////////////////////////////////////
                                            CREATE
        //////////////////////////////////////////////////////////////////////////*/

        // Load the pre-create protocol revenues.
        vars.initialProtocolRevenues = lockupDynamic.protocolRevenues(asset);

        // Load the pre-create asset balances.
        vars.balances =
            getTokenBalances(address(asset), Solarray.addresses(address(lockupDynamic), params.broker.account));
        vars.initialLockupDynamicBalance = vars.balances[0];
        vars.initialBrokerBalance = vars.balances[1];

        // Expect the relevant event to be emitted.
        vars.streamId = lockupDynamic.nextStreamId();
        vm.expectEmit({ emitter: address(lockupDynamic) });
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
        lockupDynamic.createWithMilestones(
            LockupDynamic.CreateWithMilestones({
                asset: asset,
                broker: params.broker,
                cancelable: true,
                recipient: params.recipient,
                segments: params.segments,
                sender: params.sender,
                startTime: params.startTime,
                totalAmount: vars.totalAmount
            })
        );

        // Check if the stream is settled. It is possible for a lockupDynamic stream to settle at the time of creation
        // because some segment amounts can be zero.
        vars.isSettled = lockupDynamic.refundableAmountOf(vars.streamId) == 0;
        vars.isCancelable = vars.isSettled ? false : true;

        // Assert that the stream has been created.
        LockupDynamic.Stream memory actualStream = lockupDynamic.getStream(vars.streamId);
        assertEq(actualStream.amounts, Lockup.Amounts(vars.createAmounts.deposit, 0, 0));
        assertEq(actualStream.asset, asset, "asset");
        assertEq(actualStream.endTime, vars.range.end, "endTime");
        assertEq(actualStream.isCancelable, vars.isCancelable, "isCancelable");
        assertEq(actualStream.isDepleted, false, "isDepleted");
        assertEq(actualStream.isStream, true, "isStream");
        assertEq(actualStream.segments, params.segments, "segments");
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.startTime, params.startTime, "startTime");
        assertEq(actualStream.wasCanceled, false, "wasCanceled");

        // Assert that the stream's status is correct.
        vars.actualStatus = lockupDynamic.statusOf(vars.streamId);
        if (params.startTime > getBlockTimestamp()) {
            vars.expectedStatus = Lockup.Status.PENDING;
        } else if (vars.isSettled) {
            vars.expectedStatus = Lockup.Status.SETTLED;
        } else {
            vars.expectedStatus = Lockup.Status.STREAMING;
        }
        assertEq(vars.actualStatus, vars.expectedStatus, "post-create stream status");

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = lockupDynamic.nextStreamId();
        vars.expectedNextStreamId = vars.streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "post-create nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = lockupDynamic.protocolRevenues(asset);
        vars.expectedProtocolRevenues = vars.initialProtocolRevenues + vars.createAmounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "post-create protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = lockupDynamic.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "post-create NFT owner");

        // Load the post-create asset balances.
        vars.balances =
            getTokenBalances(address(asset), Solarray.addresses(address(lockupDynamic), holder, params.broker.account));
        vars.actualLockupDynamicBalance = vars.balances[0];
        vars.actualHolderBalance = vars.balances[1];
        vars.actualBrokerBalance = vars.balances[2];

        // Assert that the contract's balance has been updated.
        vars.expectedLockupDynamicBalance =
            vars.initialLockupDynamicBalance + vars.createAmounts.deposit + vars.createAmounts.protocolFee;
        assertEq(
            vars.actualLockupDynamicBalance,
            vars.expectedLockupDynamicBalance,
            "post-create lockupDynamic contract balance"
        );

        // Assert that the holder's balance has been updated.
        vars.expectedHolderBalance = initialHolderBalance - vars.totalAmount;
        assertEq(vars.actualHolderBalance, vars.expectedHolderBalance, "post-create Holder balance");

        // Assert that the broker's balance has been updated.
        vars.expectedBrokerBalance = vars.initialBrokerBalance + vars.createAmounts.brokerFee;
        assertEq(vars.actualBrokerBalance, vars.expectedBrokerBalance, "post-create Broker balance");

        /*//////////////////////////////////////////////////////////////////////////
                                          WITHDRAW
        //////////////////////////////////////////////////////////////////////////*/

        // Simulate the passage of time.
        params.warpTimestamp = boundUint40(params.warpTimestamp, vars.range.start, vars.range.end + 100 seconds);
        vm.warp({ timestamp: params.warpTimestamp });

        // Bound the withdraw amount.
        vars.withdrawableAmount = lockupDynamic.withdrawableAmountOf(vars.streamId);
        params.withdrawAmount = boundUint128(params.withdrawAmount, 0, vars.withdrawableAmount);

        // Check if the stream has settled or will get depleted. It is possible for the stream to be just settled
        // and not depleted because the withdraw amount is fuzzed.
        vars.isDepleted = params.withdrawAmount == vars.createAmounts.deposit;
        vars.isSettled = lockupDynamic.refundableAmountOf(vars.streamId) == 0;

        // Only run the withdraw tests if the withdraw amount is not zero.
        if (params.withdrawAmount > 0) {
            // Load the pre-withdraw asset balances.
            vars.initialLockupDynamicBalance = vars.actualLockupDynamicBalance;
            vars.initialRecipientBalance = asset.balanceOf(params.recipient);

            // Expect the relevant events to be emitted.
            vm.expectEmit({ emitter: address(lockupDynamic) });
            emit WithdrawFromLockupStream({
                streamId: vars.streamId,
                to: params.recipient,
                amount: params.withdrawAmount
            });
            vm.expectEmit({ emitter: address(lockupDynamic) });
            emit MetadataUpdate({ _tokenId: vars.streamId });

            // Make the withdrawal.
            changePrank({ msgSender: params.recipient });
            lockupDynamic.withdraw({ streamId: vars.streamId, to: params.recipient, amount: params.withdrawAmount });

            // Assert that the stream's status is correct.
            vars.actualStatus = lockupDynamic.statusOf(vars.streamId);
            if (vars.isDepleted) {
                vars.expectedStatus = Lockup.Status.DEPLETED;
            } else if (vars.isSettled) {
                vars.expectedStatus = Lockup.Status.SETTLED;
            } else {
                vars.expectedStatus = Lockup.Status.STREAMING;
            }
            assertEq(vars.actualStatus, vars.expectedStatus, "post-withdraw stream status");

            // Assert that the withdrawn amount has been updated.
            vars.actualWithdrawnAmount = lockupDynamic.getWithdrawnAmount(vars.streamId);
            vars.expectedWithdrawnAmount = params.withdrawAmount;
            assertEq(vars.actualWithdrawnAmount, vars.expectedWithdrawnAmount, "post-withdraw withdrawnAmount");

            // Load the post-withdraw asset balances.
            vars.balances =
                getTokenBalances(address(asset), Solarray.addresses(address(lockupDynamic), params.recipient));
            vars.actualLockupDynamicBalance = vars.balances[0];
            vars.actualRecipientBalance = vars.balances[1];

            // Assert that the contract's balance has been updated.
            vars.expectedLockupDynamicBalance = vars.initialLockupDynamicBalance - uint256(params.withdrawAmount);
            assertEq(
                vars.actualLockupDynamicBalance,
                vars.expectedLockupDynamicBalance,
                "post-withdraw lockupDynamic contract balance"
            );

            // Assert that the Recipient's balance has been updated.
            vars.expectedRecipientBalance = vars.initialRecipientBalance + uint256(params.withdrawAmount);
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-withdraw Recipient balance");
        }

        /*//////////////////////////////////////////////////////////////////////////
                                          CANCEL
        //////////////////////////////////////////////////////////////////////////*/

        // Only run the cancel tests if the stream is neither depleted nor settled.
        if (!vars.isDepleted && !vars.isSettled) {
            // Load the pre-cancel asset balances.
            vars.balances = getTokenBalances(
                address(asset), Solarray.addresses(address(lockupDynamic), params.sender, params.recipient)
            );
            vars.initialLockupDynamicBalance = vars.balances[0];
            vars.initialSenderBalance = vars.balances[1];
            vars.initialRecipientBalance = vars.balances[2];

            // Expect the relevant events to be emitted.
            vm.expectEmit({ emitter: address(lockupDynamic) });
            vars.senderAmount = lockupDynamic.refundableAmountOf(vars.streamId);
            vars.recipientAmount = lockupDynamic.withdrawableAmountOf(vars.streamId);
            emit CancelLockupStream(
                vars.streamId, params.sender, params.recipient, vars.senderAmount, vars.recipientAmount
            );
            vm.expectEmit({ emitter: address(lockupDynamic) });
            emit MetadataUpdate({ _tokenId: vars.streamId });

            // Cancel the stream.
            changePrank({ msgSender: params.sender });
            lockupDynamic.cancel(vars.streamId);

            // Assert that the stream's status is correct.
            vars.actualStatus = lockupDynamic.statusOf(vars.streamId);
            vars.expectedStatus = vars.recipientAmount > 0 ? Lockup.Status.CANCELED : Lockup.Status.DEPLETED;
            assertEq(vars.actualStatus, vars.expectedStatus, "post-cancel stream status");

            // Load the post-cancel asset balances.
            vars.balances = getTokenBalances(
                address(asset), Solarray.addresses(address(lockupDynamic), params.sender, params.recipient)
            );
            vars.actualLockupDynamicBalance = vars.balances[0];
            vars.actualSenderBalance = vars.balances[1];
            vars.actualRecipientBalance = vars.balances[2];

            // Assert that the contract's balance has been updated.
            vars.expectedLockupDynamicBalance = vars.initialLockupDynamicBalance - uint256(vars.senderAmount);
            assertEq(
                vars.actualLockupDynamicBalance,
                vars.expectedLockupDynamicBalance,
                "post-cancel lockupDynamic contract balance"
            );

            // Assert that the Sender's balance has been updated.
            vars.expectedSenderBalance = vars.initialSenderBalance + uint256(vars.senderAmount);
            assertEq(vars.actualSenderBalance, vars.expectedSenderBalance, "post-cancel Sender balance");

            // Assert that the Recipient's balance has not changed.
            vars.expectedRecipientBalance = vars.initialRecipientBalance;
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-cancel Recipient balance");
        }

        // Assert that the NFT has not been burned.
        vars.actualNFTOwner = lockupDynamic.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "post-cancel NFT owner");
    }
}
