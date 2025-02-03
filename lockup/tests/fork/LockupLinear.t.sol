// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { Solarray } from "solarray/src/Solarray.sol";
import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { ISablierLockupBase } from "src/interfaces/ISablierLockupBase.sol";
import { Broker, Lockup, LockupLinear } from "src/types/DataTypes.sol";
import { Fork_Test } from "./Fork.t.sol";

abstract contract Lockup_Linear_Fork_Test is Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkToken) Fork_Test(forkToken) { }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fork_Test.setUp();

        // Approve {SablierLockup} to transfer the token holder's tokens.
        // We use a low-level call to ignore reverts because the token can have the missing return value bug.
        (bool success,) = address(FORK_TOKEN).call(abi.encodeCall(IERC20.approve, (address(lockup), MAX_UINT256)));
        success;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    struct Params {
        address sender;
        address recipient;
        uint128 totalAmount;
        uint128 withdrawAmount;
        uint40 warpTimestamp;
        Lockup.Timestamps timestamps;
        LockupLinear.UnlockAmounts unlockAmounts;
        uint40 cliffTime;
        Broker broker;
    }

    struct Vars {
        // Generic vars
        uint256 actualLockupBalance;
        uint256 actualHolderBalance;
        address actualNFTOwner;
        uint256 actualRecipientBalance;
        Lockup.Status actualStatus;
        uint256[] balances;
        uint40 blockTimestamp;
        uint40 endTimeLowerBound;
        uint256 expectedLockupBalance;
        uint256 expectedHolderBalance;
        address expectedNFTOwner;
        uint256 expectedRecipientBalance;
        Lockup.Status expectedStatus;
        bool hasCliff;
        uint256 initialLockupBalance;
        uint256 initialRecipientBalance;
        bool isCancelable;
        bool isDepleted;
        bool isSettled;
        uint256 streamId;
        uint128 streamedAmount;
        // Create vars
        uint256 actualBrokerBalance;
        uint256 actualNextStreamId;
        Lockup.CreateAmounts createAmounts;
        uint256 expectedBrokerBalance;
        uint256 expectedNextStreamId;
        uint256 initialBrokerBalance;
        // Withdraw vars
        uint128 actualWithdrawnAmount;
        uint128 expectedWithdrawnAmount;
        uint256 initialLockupBalanceETH;
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
    /// - It should perform all expected ERC-20 transfers
    /// - It should create the stream
    /// - It should bump the next stream ID
    /// - It should mint the NFT
    /// - It should emit a {MetadataUpdate} event
    /// - It should emit a {CreateLockupLinearStream} event
    /// - It may make a withdrawal and pay a fee
    /// - It may update the withdrawn amounts
    /// - It may emit a {WithdrawFromLockupStream} event
    /// - It may cancel the stream
    /// - It may emit a {CancelLockupStream} event
    ///
    /// Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the sender, recipient, and broker
    /// - Multiple values for the total amount
    /// - Multiple values for the withdraw amount, including zero
    /// - Start time in the past
    /// - Start time in the present
    /// - Start time in the future
    /// - Multiple values for the cliff time and the end time
    /// - Cliff time zero and not zero
    /// - Multiple values for the broker fee, including zero
    /// - The whole gamut of stream statuses
    function testForkFuzz_CreateWithdrawCancel(Params memory params) external {
        checkUsers(params.sender, params.recipient, params.broker.account, address(lockup));

        // Bound the parameters.
        Vars memory vars;
        vars.blockTimestamp = getBlockTimestamp();
        params.broker.fee = _bound(params.broker.fee, 0, MAX_BROKER_FEE);
        params.timestamps.start = boundUint40(
            params.timestamps.start, vars.blockTimestamp - 1000 seconds, vars.blockTimestamp + 10_000 seconds
        );
        params.totalAmount = boundUint128(params.totalAmount, 1, uint128(initialHolderBalance));

        // The cliff time must be either zero or greater than the start time.
        vars.hasCliff = params.cliffTime > 0;
        params.cliffTime = vars.hasCliff
            ? boundUint40(params.cliffTime, params.timestamps.start + 1 seconds, params.timestamps.start + 52 weeks)
            : 0;

        // Bound the end time so that it is always greater than the start time, and the cliff time.
        vars.endTimeLowerBound = maxOfTwo(params.timestamps.start, params.cliffTime);
        params.timestamps.end =
            boundUint40(params.timestamps.end, vars.endTimeLowerBound + 1 seconds, MAX_UNIX_TIMESTAMP);

        // Calculate the broker fee amount and the deposit amount.
        vars.createAmounts.brokerFee = ud(params.totalAmount).mul(params.broker.fee).intoUint128();
        vars.createAmounts.deposit = params.totalAmount - vars.createAmounts.brokerFee;

        // Bound the unlock amounts.
        params.unlockAmounts.start = boundUint128(params.unlockAmounts.start, 0, vars.createAmounts.deposit);
        params.unlockAmounts.cliff = vars.hasCliff
            ? boundUint128(params.unlockAmounts.cliff, 0, vars.createAmounts.deposit - params.unlockAmounts.start)
            : 0;

        // Make the holder the caller.
        resetPrank(forkTokenHolder);

        /*//////////////////////////////////////////////////////////////////////////
                                            CREATE
        //////////////////////////////////////////////////////////////////////////*/

        // Load the pre-create token balances.
        vars.balances =
            getTokenBalances(address(FORK_TOKEN), Solarray.addresses(address(lockup), params.broker.account));
        vars.initialLockupBalance = vars.balances[0];
        vars.initialBrokerBalance = vars.balances[1];

        vars.streamId = lockup.nextStreamId();

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: vars.streamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupLinearStream({
            streamId: vars.streamId,
            commonParams: Lockup.CreateEventCommon({
                funder: forkTokenHolder,
                sender: params.sender,
                recipient: params.recipient,
                amounts: vars.createAmounts,
                token: FORK_TOKEN,
                cancelable: true,
                transferable: true,
                timestamps: params.timestamps,
                shape: "Linear Shape",
                broker: params.broker.account
            }),
            cliffTime: params.cliffTime,
            unlockAmounts: params.unlockAmounts
        });

        // Create the stream.
        lockup.createWithTimestampsLL(
            Lockup.CreateWithTimestamps({
                sender: params.sender,
                recipient: params.recipient,
                totalAmount: params.totalAmount,
                token: FORK_TOKEN,
                cancelable: true,
                transferable: true,
                timestamps: params.timestamps,
                shape: "Linear Shape",
                broker: params.broker
            }),
            params.unlockAmounts,
            params.cliffTime
        );

        vars.streamedAmount = calculateLockupLinearStreamedAmount(
            params.timestamps.start,
            params.cliffTime,
            params.timestamps.end,
            vars.createAmounts.deposit,
            params.unlockAmounts
        );

        // Check if the stream is settled. It is possible for a Lockup Linear stream to settle at the time of creation
        // in case 1. the start unlock amount equals the deposited amount 2. end time is in the past.
        if (vars.streamedAmount == vars.createAmounts.deposit) {
            vars.isSettled = true;
        } else {
            vars.isSettled = false;
        }
        vars.isCancelable = vars.isSettled ? false : true;

        // Assert that the stream has been created.
        assertEq(lockup.getCliffTime(vars.streamId), params.cliffTime, "cliffTime");
        assertEq(lockup.getDepositedAmount(vars.streamId), vars.createAmounts.deposit, "depositedAmount");
        assertEq(lockup.isCancelable(vars.streamId), vars.isCancelable, "isCancelable");
        assertFalse(lockup.isDepleted(vars.streamId), "isDepleted");
        assertTrue(lockup.isStream(vars.streamId), "isStream");
        assertTrue(lockup.isTransferable(vars.streamId), "isTransferable");
        assertEq(lockup.getEndTime(vars.streamId), params.timestamps.end, "endTime");
        assertEq(lockup.getRecipient(vars.streamId), params.recipient, "recipient");
        assertEq(lockup.getSender(vars.streamId), params.sender, "sender");
        assertEq(lockup.getStartTime(vars.streamId), params.timestamps.start, "startTime");
        assertEq(lockup.getUnderlyingToken(vars.streamId), FORK_TOKEN, "underlyingToken");
        assertEq(lockup.getUnlockAmounts(vars.streamId).start, params.unlockAmounts.start, "unlockAmounts.start");
        assertEq(lockup.getUnlockAmounts(vars.streamId).cliff, params.unlockAmounts.cliff, "unlockAmounts.cliff");
        assertFalse(lockup.wasCanceled(vars.streamId), "wasCanceled");

        // Assert that the stream's status is correct.
        vars.actualStatus = lockup.statusOf(vars.streamId);
        if (vars.streamedAmount == vars.createAmounts.deposit) {
            vars.expectedStatus = Lockup.Status.SETTLED;
        } else if (params.timestamps.start > vars.blockTimestamp) {
            vars.expectedStatus = Lockup.Status.PENDING;
        } else {
            vars.expectedStatus = Lockup.Status.STREAMING;
        }
        assertEq(vars.actualStatus, vars.expectedStatus, "post-create stream status");

        // Assert that the next stream ID has been bumped.
        vars.actualNextStreamId = lockup.nextStreamId();
        vars.expectedNextStreamId = vars.streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "post-create nextStreamId");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = lockup.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "post-create NFT owner");

        // Load the post-create token balances.
        vars.balances = getTokenBalances(
            address(FORK_TOKEN), Solarray.addresses(address(lockup), forkTokenHolder, params.broker.account)
        );
        vars.actualLockupBalance = vars.balances[0];
        vars.actualHolderBalance = vars.balances[1];
        vars.actualBrokerBalance = vars.balances[2];

        // Assert that the Lockup contract's balance has been updated.
        vars.expectedLockupBalance = vars.initialLockupBalance + vars.createAmounts.deposit;
        assertEq(vars.actualLockupBalance, vars.expectedLockupBalance, "post-create Lockup balance");

        // Assert that the holder's balance has been updated.
        vars.expectedHolderBalance = initialHolderBalance - params.totalAmount;
        assertEq(vars.actualHolderBalance, vars.expectedHolderBalance, "post-create Holder balance");

        // Assert that the broker's balance has been updated.
        vars.expectedBrokerBalance = vars.initialBrokerBalance + vars.createAmounts.brokerFee;
        assertEq(vars.actualBrokerBalance, vars.expectedBrokerBalance, "post-create Broker balance");

        /*//////////////////////////////////////////////////////////////////////////
                                          WITHDRAW
        //////////////////////////////////////////////////////////////////////////*/

        // Simulate the passage of time.
        params.warpTimestamp = boundUint40(
            params.warpTimestamp,
            vars.hasCliff ? params.cliffTime : params.timestamps.start + 1 seconds,
            params.timestamps.end + 100 seconds
        );
        vm.warp({ newTimestamp: params.warpTimestamp });

        // Bound the withdraw amount.
        vars.withdrawableAmount = lockup.withdrawableAmountOf(vars.streamId);
        params.withdrawAmount = boundUint128(params.withdrawAmount, 0, vars.withdrawableAmount);

        // Check if the stream has settled or will get depleted. It is possible for the stream to be just settled
        // and not depleted because the withdraw amount is fuzzed.
        vars.isSettled = lockup.refundableAmountOf(vars.streamId) == 0;
        vars.isDepleted = params.withdrawAmount == vars.createAmounts.deposit;

        // Only run the withdraw tests if the withdraw amount is not zero.
        if (params.withdrawAmount > 0) {
            // Load the pre-withdraw token balances.
            vars.initialLockupBalance = vars.actualLockupBalance;
            vars.initialLockupBalanceETH = address(lockup).balance;
            vars.initialRecipientBalance = FORK_TOKEN.balanceOf(params.recipient);

            // Expect the relevant events to be emitted.
            vm.expectEmit({ emitter: address(lockup) });
            emit ISablierLockupBase.WithdrawFromLockupStream({
                streamId: vars.streamId,
                to: params.recipient,
                token: FORK_TOKEN,
                amount: params.withdrawAmount
            });
            vm.expectEmit({ emitter: address(lockup) });
            emit IERC4906.MetadataUpdate({ _tokenId: vars.streamId });

            // Make the withdrawal and pay a fee.
            resetPrank({ msgSender: params.recipient });
            vm.deal({ account: params.recipient, newBalance: 100 ether });
            lockup.withdraw{ value: FEE }({
                streamId: vars.streamId,
                to: params.recipient,
                amount: params.withdrawAmount
            });

            // Assert that the stream's status is correct.
            vars.actualStatus = lockup.statusOf(vars.streamId);
            if (vars.isDepleted) {
                vars.expectedStatus = Lockup.Status.DEPLETED;
            } else if (vars.isSettled) {
                vars.expectedStatus = Lockup.Status.SETTLED;
            } else {
                vars.expectedStatus = Lockup.Status.STREAMING;
            }
            assertEq(vars.actualStatus, vars.expectedStatus, "post-withdraw stream status");

            // Assert that the withdrawn amount has been updated.
            vars.actualWithdrawnAmount = lockup.getWithdrawnAmount(vars.streamId);
            vars.expectedWithdrawnAmount = params.withdrawAmount;
            assertEq(vars.actualWithdrawnAmount, vars.expectedWithdrawnAmount, "post-withdraw withdrawnAmount");

            // Load the post-withdraw token balances.
            vars.balances = getTokenBalances(address(FORK_TOKEN), Solarray.addresses(address(lockup), params.recipient));
            vars.actualLockupBalance = vars.balances[0];
            vars.actualRecipientBalance = vars.balances[1];

            // Assert that the contract's balance has been updated.
            vars.expectedLockupBalance = vars.initialLockupBalance - uint256(params.withdrawAmount);
            assertEq(vars.actualLockupBalance, vars.expectedLockupBalance, "post-withdraw Lockup balance");

            // Assert that the contract's ETH balance has been updated.
            assertEq(address(lockup).balance, vars.initialLockupBalanceETH + FEE, "post-withdraw Lockup balance ETH");

            // Assert that the Recipient's balance has been updated.
            vars.expectedRecipientBalance = vars.initialRecipientBalance + uint256(params.withdrawAmount);
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-withdraw Recipient balance");
        }

        /*//////////////////////////////////////////////////////////////////////////
                                          CANCEL
        //////////////////////////////////////////////////////////////////////////*/

        // Only run the cancel tests if the stream is neither depleted nor settled.
        if (!vars.isDepleted && !vars.isSettled) {
            // Load the pre-cancel token balances.
            vars.balances = getTokenBalances(
                address(FORK_TOKEN), Solarray.addresses(address(lockup), params.sender, params.recipient)
            );
            vars.initialLockupBalance = vars.balances[0];
            vars.initialSenderBalance = vars.balances[1];
            vars.initialRecipientBalance = vars.balances[2];

            // Expect the relevant events to be emitted.
            vm.expectEmit({ emitter: address(lockup) });
            vars.senderAmount = lockup.refundableAmountOf(vars.streamId);
            vars.recipientAmount = lockup.withdrawableAmountOf(vars.streamId);
            emit ISablierLockupBase.CancelLockupStream(
                vars.streamId, params.sender, params.recipient, FORK_TOKEN, vars.senderAmount, vars.recipientAmount
            );
            vm.expectEmit({ emitter: address(lockup) });
            emit IERC4906.MetadataUpdate({ _tokenId: vars.streamId });

            // Cancel the stream.
            resetPrank({ msgSender: params.sender });
            lockup.cancel(vars.streamId);

            // Assert that the stream's status is correct.
            vars.actualStatus = lockup.statusOf(vars.streamId);
            vars.expectedStatus = vars.recipientAmount > 0 ? Lockup.Status.CANCELED : Lockup.Status.DEPLETED;
            assertEq(vars.actualStatus, vars.expectedStatus, "post-cancel stream status");

            // Load the post-cancel token balances.
            vars.balances = getTokenBalances(
                address(FORK_TOKEN), Solarray.addresses(address(lockup), params.sender, params.recipient)
            );
            vars.actualLockupBalance = vars.balances[0];
            vars.actualSenderBalance = vars.balances[1];
            vars.actualRecipientBalance = vars.balances[2];

            // Assert that the contract's balance has been updated.
            vars.expectedLockupBalance = vars.initialLockupBalance - uint256(vars.senderAmount);
            assertEq(vars.actualLockupBalance, vars.expectedLockupBalance, "post-cancel Lockup balance");

            // Assert that the Sender's balance has been updated.
            vars.expectedSenderBalance = vars.initialSenderBalance + uint256(vars.senderAmount);
            assertEq(vars.actualSenderBalance, vars.expectedSenderBalance, "post-cancel Sender balance");

            // Assert that the Recipient's balance has not changed.
            vars.expectedRecipientBalance = vars.initialRecipientBalance;
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-cancel Recipient balance");
        }

        // Assert that the not burned NFT.
        vars.actualNFTOwner = lockup.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "post-cancel NFT owner");
    }
}
