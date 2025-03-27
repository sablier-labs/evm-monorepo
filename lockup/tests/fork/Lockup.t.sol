// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Solarray } from "solarray/src/Solarray.sol";
import { ISablierLockupBase } from "src/interfaces/ISablierLockupBase.sol";
import { Lockup, LockupLinear, LockupDynamic, LockupTranched } from "src/types/DataTypes.sol";

import { Fork_Test } from "./Fork.t.sol";

/// @notice Common Lockup logic needed by all the fork tests.
abstract contract Lockup_Fork_Test is Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    // Struct with parameters to be fuzzed during the fork tests.
    struct Params {
        Lockup.CreateWithTimestamps create;
        uint40 cliffTime;
        LockupDynamic.Segment[] segments;
        LockupTranched.Tranche[] tranches;
        LockupLinear.UnlockAmounts unlockAmounts;
        uint40 warpTimestamp;
        uint128 withdrawAmount;
    }

    // Struct to manage storage variables to be used across contracts.
    struct Vars {
        // Initial values
        uint256 initialLockupBalance;
        uint256 initialLockupBalanceETH;
        uint256 initialRecipientBalance;
        uint256 initialSenderBalance;
        // Final values
        uint256 actualHolderBalance;
        uint256 actualLockupBalance;
        uint256 actualRecipientBalance;
        uint256 actualSenderBalance;
        // Expected values
        Lockup.Status expectedStatus;
        // Generics
        bool hasCliff;
        bool isDepleted;
        bool isSettled;
        uint128 recipientAmount;
        uint128 senderAmount;
        uint128 streamedAmount;
        uint256 streamId;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Vars internal vars;
    Lockup.Model internal lockupModel;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkToken) Fork_Test(forkToken) { }

    /*//////////////////////////////////////////////////////////////////////////
                                  CREATE HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A pre-create helper function to set up the parameters for the stream creation.
    function preCreateStream(Params memory params) internal {
        checkUsers(params.create.sender, params.create.recipient, address(lockup));

        // Store the pre-create token balances of Lockup and Holder.
        uint256[] memory balances =
            getTokenBalances(address(FORK_TOKEN), Solarray.addresses(address(lockup), forkTokenHolder));
        vars.initialLockupBalance = balances[0];
        initialHolderBalance = uint128(balances[1]);

        // Store the next stream ID.
        vars.streamId = lockup.nextStreamId();

        // Bound the start time.
        params.create.timestamps.start = boundUint40(
            params.create.timestamps.start, getBlockTimestamp() - 1000 seconds, getBlockTimestamp() + 10_000 seconds
        );

        vars.hasCliff = params.cliffTime > 0;
        // Bound the cliff time. Since it is only relevant to the Linear model, it will be ignored for the Dynamic
        // and Tranched models.
        params.cliffTime = vars.hasCliff
            ? boundUint40(
                params.cliffTime, params.create.timestamps.start + 1 seconds, params.create.timestamps.start + 52 weeks
            )
            : 0;

        // Set fixed values for shape name and token.
        params.create.shape = "Custom shape";
        params.create.token = FORK_TOKEN;

        // Make the stream cancelable so that the cancel tests can be run.
        params.create.cancelable = true;

        if (lockupModel == Lockup.Model.LOCKUP_LINEAR) {
            // Bound the deposit amount.
            params.create.depositAmount = boundUint128(params.create.depositAmount, 1, initialHolderBalance);

            // Bound the minimum value of end time so that it is always greater than the start time, and the cliff time.
            uint40 endTimeLowerBound = maxOfTwo(params.create.timestamps.start, params.cliffTime);

            // Bound the end time of the stream.
            params.create.timestamps.end =
                boundUint40(params.create.timestamps.end, endTimeLowerBound + 1 seconds, MAX_UNIX_TIMESTAMP);

            // Bound the unlock amounts.
            params.unlockAmounts.start = boundUint128(params.unlockAmounts.start, 0, params.create.depositAmount);
            // Bound the cliff unlock amount only if the cliff is set.
            params.unlockAmounts.cliff = vars.hasCliff
                ? boundUint128(params.unlockAmounts.cliff, 0, params.create.depositAmount - params.unlockAmounts.start)
                : 0;
        }

        if (lockupModel == Lockup.Model.LOCKUP_DYNAMIC) {
            fuzzSegmentTimestamps(params.segments, params.create.timestamps.start);

            // Fuzz the segment amounts and calculate the deposit.
            params.create.depositAmount =
                fuzzDynamicStreamAmounts({ upperBound: initialHolderBalance, segments: params.segments });

            // Bound the end time of the stream.
            params.create.timestamps.end = params.segments[params.segments.length - 1].timestamp;
        }

        if (lockupModel == Lockup.Model.LOCKUP_TRANCHED) {
            fuzzTrancheTimestamps(params.tranches, params.create.timestamps.start);

            // Fuzz the tranche amounts and calculate the deposit.
            params.create.depositAmount =
                fuzzTranchedStreamAmounts({ upperBound: initialHolderBalance, tranches: params.tranches });

            // Bound the end time of the stream.
            params.create.timestamps.end = params.tranches[params.tranches.length - 1].timestamp;
        }
    }

    /// @dev A post-create helper function to compare values and set up the parameters for withdraw and cancel tests.
    function postCreateStream(Params memory params) internal {
        // Check if the stream is settled. It is possible for a Lockup stream to settle at the time of creation in the
        // following cases:
        // 1. The streamed amount equals the deposited amount.
        // 2. The end time is in the past.
        vars.isSettled = vars.streamedAmount >= params.create.depositAmount
            || lockup.getEndTime(vars.streamId) <= getBlockTimestamp();

        // Check that the stream status is correct.
        if (lockup.getStartTime(vars.streamId) > getBlockTimestamp()) {
            vars.expectedStatus = Lockup.Status.PENDING;
        } else if (vars.isSettled) {
            vars.expectedStatus = Lockup.Status.SETTLED;
        } else {
            vars.expectedStatus = Lockup.Status.STREAMING;
        }
        assertEq(lockup.statusOf(vars.streamId), vars.expectedStatus, "post-create stream status");

        if (vars.isSettled) {
            // If the stream is settled, it should not be cancelable.
            assertFalse(lockup.isCancelable(vars.streamId), "isCancelable");
        } else {
            // Otherwise, it should match the parameter value.
            assertEq(lockup.isCancelable(vars.streamId), params.create.cancelable, "isCancelable");
        }

        // Assert that the aggregate amount has been updated.
        assertEq(
            lockup.aggregateAmount(FORK_TOKEN),
            vars.initialLockupBalance + params.create.depositAmount,
            "aggregateAmount"
        );

        // Store the post-create token balances of Lockup and Holder.
        uint256[] memory balances =
            getTokenBalances(address(FORK_TOKEN), Solarray.addresses(address(lockup), forkTokenHolder));
        vars.actualLockupBalance = balances[0];
        vars.actualHolderBalance = balances[1];

        // Assert that the Lockup contract's balance has been updated.
        uint256 expectedLockupBalance = vars.initialLockupBalance + params.create.depositAmount;
        assertEq(vars.actualLockupBalance, expectedLockupBalance, "post-create Lockup balance");

        // Assert that the holder's balance has been updated.
        uint128 expectedHolderBalance = initialHolderBalance - params.create.depositAmount;
        assertEq(vars.actualHolderBalance, expectedHolderBalance, "post-create Holder balance");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  WITHDRAW HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A shared withdraw function to be used by all the fork tests.
    function withdraw(Params memory params) internal {
        // Bound the withdraw amount.
        params.withdrawAmount = boundUint128(params.withdrawAmount, 0, lockup.withdrawableAmountOf(vars.streamId));

        // Check if the stream has settled or will get depleted. It is possible for the stream to be just settled
        // and not depleted because the withdraw amount is fuzzed.
        vars.isSettled = vars.streamedAmount >= params.create.depositAmount
            || lockup.getEndTime(vars.streamId) <= getBlockTimestamp();
        vars.isDepleted = params.withdrawAmount == params.create.depositAmount;

        // Run the withdraw tests only if the withdraw amount is not zero.
        if (params.withdrawAmount > 0) {
            // Load the pre-withdraw token balances.
            vars.initialLockupBalance = vars.actualLockupBalance;
            vars.initialLockupBalanceETH = address(lockup).balance;
            vars.initialRecipientBalance = FORK_TOKEN.balanceOf(params.create.recipient);

            // Expect the relevant events to be emitted.
            vm.expectEmit({ emitter: address(lockup) });
            emit ISablierLockupBase.WithdrawFromLockupStream({
                streamId: vars.streamId,
                to: params.create.recipient,
                token: FORK_TOKEN,
                amount: params.withdrawAmount
            });
            vm.expectEmit({ emitter: address(lockup) });
            emit IERC4906.MetadataUpdate({ _tokenId: vars.streamId });

            // Make the withdrawal and pay a fee.
            setMsgSender(params.create.recipient);
            vm.deal({ account: params.create.recipient, newBalance: 100 ether });
            lockup.withdraw{ value: FEE }({
                streamId: vars.streamId,
                to: params.create.recipient,
                amount: params.withdrawAmount
            });

            // Assert that the stream's status is correct.
            if (vars.isDepleted) {
                vars.expectedStatus = Lockup.Status.DEPLETED;
            } else if (vars.isSettled) {
                vars.expectedStatus = Lockup.Status.SETTLED;
            } else {
                vars.expectedStatus = Lockup.Status.STREAMING;
            }
            assertEq(lockup.statusOf(vars.streamId), vars.expectedStatus, "post-withdraw stream status");

            // Assert that the withdrawn amount has been updated.
            assertEq(lockup.getWithdrawnAmount(vars.streamId), params.withdrawAmount, "post-withdraw withdrawnAmount");

            // Assert that the aggregate amount has been updated.
            assertEq(
                lockup.aggregateAmount(FORK_TOKEN), vars.initialLockupBalance - params.withdrawAmount, "aggregateAmount"
            );

            // Load the post-withdraw token balances.
            uint256[] memory balances =
                getTokenBalances(address(FORK_TOKEN), Solarray.addresses(address(lockup), params.create.recipient));
            vars.actualLockupBalance = balances[0];
            vars.actualRecipientBalance = balances[1];

            // Assert that the contract's balance has been updated.
            uint256 expectedLockupBalance = vars.initialLockupBalance - params.withdrawAmount;
            assertEq(vars.actualLockupBalance, expectedLockupBalance, "post-withdraw Lockup balance");

            // Assert that the contract's ETH balance has been updated.
            assertEq(address(lockup).balance, vars.initialLockupBalanceETH + FEE, "post-withdraw Lockup balance ETH");

            // Assert that the Recipient's balance has been updated.
            uint256 expectedRecipientBalance = vars.initialRecipientBalance + params.withdrawAmount;
            assertEq(vars.actualRecipientBalance, expectedRecipientBalance, "post-withdraw Recipient balance");
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  CANCEL HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A shared cancel function to be used by all the fork tests.
    function cancel(Params memory params) internal {
        // Run the cancel tests only if the stream is cancelable and is neither depleted nor settled.
        if (params.create.cancelable && !vars.isDepleted && !vars.isSettled) {
            // Load the pre-cancel token balances.
            uint256[] memory balances = getTokenBalances(
                address(FORK_TOKEN), Solarray.addresses(address(lockup), params.create.sender, params.create.recipient)
            );
            vars.initialLockupBalance = balances[0];
            vars.initialSenderBalance = balances[1];
            vars.initialRecipientBalance = balances[2];

            // Expect the relevant events to be emitted.
            vm.expectEmit({ emitter: address(lockup) });
            vars.senderAmount = lockup.refundableAmountOf(vars.streamId);
            vars.recipientAmount = lockup.withdrawableAmountOf(vars.streamId);
            emit ISablierLockupBase.CancelLockupStream(
                vars.streamId,
                params.create.sender,
                params.create.recipient,
                FORK_TOKEN,
                vars.senderAmount,
                vars.recipientAmount
            );
            vm.expectEmit({ emitter: address(lockup) });
            emit IERC4906.MetadataUpdate({ _tokenId: vars.streamId });

            // Cancel the stream.
            setMsgSender(params.create.sender);
            uint128 refundedAmount = lockup.cancel(vars.streamId);

            // Assert that the refunded amount is correct.
            assertEq(refundedAmount, vars.senderAmount, "refundedAmount");

            // Assert that the stream's status is correct.
            vars.expectedStatus = vars.recipientAmount > 0 ? Lockup.Status.CANCELED : Lockup.Status.DEPLETED;
            assertEq(lockup.statusOf(vars.streamId), vars.expectedStatus, "post-cancel stream status");

            // Assert that the aggregate amount has been updated.
            assertEq(lockup.aggregateAmount(FORK_TOKEN), vars.initialLockupBalance - refundedAmount, "aggregateAmount");

            // Load the post-cancel token balances.
            balances = getTokenBalances(
                address(FORK_TOKEN), Solarray.addresses(address(lockup), params.create.sender, params.create.recipient)
            );
            vars.actualLockupBalance = balances[0];
            vars.actualSenderBalance = balances[1];
            vars.actualRecipientBalance = balances[2];

            // Assert that the contract's balance has been updated.
            uint256 expectedLockupBalance = vars.initialLockupBalance - vars.senderAmount;
            assertEq(vars.actualLockupBalance, expectedLockupBalance, "post-cancel Lockup balance");

            // Assert that the Sender's balance has been updated.
            uint256 expectedSenderBalance = vars.initialSenderBalance + vars.senderAmount;
            assertEq(vars.actualSenderBalance, expectedSenderBalance, "post-cancel Sender balance");

            // Assert that the Recipient's balance has not changed.
            assertEq(vars.actualRecipientBalance, vars.initialRecipientBalance, "post-cancel Recipient balance");
        }

        // Assert that the not burned NFT.
        assertEq(lockup.ownerOf(vars.streamId), params.create.recipient, "post-cancel NFT owner");
    }
}
