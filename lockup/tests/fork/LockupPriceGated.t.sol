// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Solarray } from "solarray/src/Solarray.sol";

import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { ISablierLockupPriceGated } from "src/interfaces/ISablierLockupPriceGated.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupPriceGated } from "src/types/LockupPriceGated.sol";

import { Lockup_Fork_Test } from "./Lockup.t.sol";

abstract contract Lockup_PriceGated_Fork_Test is Lockup_Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    // Struct with parameters to be fuzzed during the fork tests.
    struct ParamsLPG {
        Lockup.CreateWithTimestamps create;
        uint128 mockPrice;
        uint128 targetPrice;
        uint40 warpTimestamp;
        uint128 withdrawAmount;
    }

    // Struct to manage storage variables for LPG tests.
    struct VarsLPG {
        // Initial values
        uint256 initialAggregateAmount;
        uint256 initialComptrollerBalanceETH;
        uint256 initialLockupBalance;
        uint256 initialRecipientBalance;
        uint256 initialSenderBalance;
        // Final values
        uint256 actualHolderBalance;
        uint256 actualLockupBalance;
        uint256 actualRecipientBalance;
        uint256 actualSenderBalance;
        // Expected values
        uint256 expectedAggregateAmount;
        Lockup.Status expectedStatus;
        // Generics
        bool isDepleted;
        uint128 recipientAmount;
        uint128 senderAmount;
        uint256 streamId;
        Lockup.Timestamps timestamps;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The Chainlink price feed oracle used for this test.
    AggregatorV3Interface internal immutable ORACLE;

    VarsLPG internal varsLPG;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkToken, AggregatorV3Interface oracle) Lockup_Fork_Test(forkToken) {
        lockupModel = Lockup.Model.LOCKUP_PRICE_GATED;
        ORACLE = oracle;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checklist:
    ///
    /// - It should perform all expected ERC-20 transfers
    /// - It should create the stream
    /// - It should bump the next stream ID
    /// - It should mint the NFT
    /// - It should emit a {MetadataUpdate} event
    /// - It should emit a {CreateLockupPriceGatedStream} event
    /// - It should make a withdrawal.
    /// - It should update the withdrawn amounts
    /// - It should emit a {WithdrawFromLockupStream} event
    ///
    /// Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the sender, and recipient
    /// - Multiple values for the deposit amount
    /// - Multiple values for the withdraw amount
    /// - Multiple values for the duration
    /// - Multiple values for the target price
    /// - Oracle mock price above target price
    function testForkFuzz_CreateWithdraw(ParamsLPG memory params) external {
        /*//////////////////////////////////////////////////////////////////////////
                                            CREATE
        //////////////////////////////////////////////////////////////////////////*/

        // Bound the fuzzed parameters and load values into `varsLPG`.
        _preCreateStream(params);

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: varsLPG.streamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupPriceGated.CreateLockupPriceGatedStream({
            streamId: varsLPG.streamId,
            oracle: ORACLE,
            targetPrice: params.targetPrice
        });

        // Create the stream.
        lockup.createWithTimestampsLPG({
            params: params.create,
            unlockParams: LockupPriceGated.UnlockParams(ORACLE, params.targetPrice)
        });

        // Assert that the stream is created with the correct parameters.
        assertEq(lockup.getDepositedAmount(varsLPG.streamId), params.create.depositAmount, "depositedAmount");
        assertEq(lockup.getEndTime(varsLPG.streamId), params.create.timestamps.end, "endTime");
        assertEq(lockup.getRecipient(varsLPG.streamId), params.create.recipient, "recipient");
        assertEq(lockup.getSender(varsLPG.streamId), params.create.sender, "sender");
        assertEq(lockup.getStartTime(varsLPG.streamId), params.create.timestamps.start, "startTime");
        assertEq(lockup.getUnderlyingToken(varsLPG.streamId), params.create.token, "underlyingToken");
        assertEq(lockup.getWithdrawnAmount(varsLPG.streamId), 0, "withdrawnAmount");
        assertFalse(lockup.isDepleted(varsLPG.streamId), "isDepleted");
        assertTrue(lockup.isStream(varsLPG.streamId), "isStream");
        assertEq(lockup.isTransferable(varsLPG.streamId), params.create.transferable, "isTransferable");
        assertEq(lockup.nextStreamId(), varsLPG.streamId + 1, "post-create nextStreamId");
        assertFalse(lockup.wasCanceled(varsLPG.streamId), "wasCanceled");
        assertEq(lockup.ownerOf(varsLPG.streamId), params.create.recipient, "post-create NFT owner");
        assertEq(lockup.getLockupModel(varsLPG.streamId), Lockup.Model.LOCKUP_PRICE_GATED);

        // It should store the unlock params.
        LockupPriceGated.UnlockParams memory unlockParams = lockup.getPriceGatedUnlockParams(varsLPG.streamId);
        assertEq(address(unlockParams.oracle), address(ORACLE), "oracle");
        assertEq(unlockParams.targetPrice, params.targetPrice, "targetPrice");

        // The stream should be in STREAMING status right after creation (since price < target).
        assertEq(lockup.statusOf(varsLPG.streamId), Lockup.Status.STREAMING, "post-create stream status");

        // The stream should be cancelable right after creation.
        assertTrue(lockup.isCancelable(varsLPG.streamId), "post-create isCancelable");

        // Assert that the aggregate amount has been updated.
        varsLPG.expectedAggregateAmount = varsLPG.initialAggregateAmount + params.create.depositAmount;
        assertEq(lockup.aggregateAmount(FORK_TOKEN), varsLPG.expectedAggregateAmount, "aggregateAmount");

        // Store the post-create token balances of Lockup and Holder.
        uint256[] memory balances =
            getTokenBalances(address(FORK_TOKEN), Solarray.addresses(address(lockup), forkTokenHolder));
        varsLPG.actualLockupBalance = balances[0];
        varsLPG.actualHolderBalance = balances[1];

        // Assert that the Lockup contract's balance has been updated.
        uint256 expectedLockupBalance = varsLPG.initialLockupBalance + params.create.depositAmount;
        assertEq(varsLPG.actualLockupBalance, expectedLockupBalance, "post-create Lockup balance");

        // Assert that the holder's balance has been updated.
        uint128 expectedHolderBalance = initialHolderBalance - params.create.depositAmount;
        assertEq(varsLPG.actualHolderBalance, expectedHolderBalance, "post-create Holder balance");

        /*//////////////////////////////////////////////////////////////////////////
                                          WITHDRAW
        //////////////////////////////////////////////////////////////////////////*/

        // Warp to a random timestamp.
        params.warpTimestamp =
            boundUint40(params.warpTimestamp, getBlockTimestamp() + 1, varsLPG.timestamps.end + 100 seconds);
        vm.warp({ newTimestamp: params.warpTimestamp });

        // Bound the mock price so that its above the target price.
        params.mockPrice = boundUint128(params.mockPrice, params.targetPrice, params.targetPrice * 2);

        // Mock the oracle to return the mocked price.
        vm.mockCall(
            address(ORACLE),
            abi.encodeCall(AggregatorV3Interface.latestRoundData, ()),
            abi.encode(uint80(1), int256(uint256(params.mockPrice)), block.timestamp, block.timestamp, uint80(1))
        );

        // Bound the withdraw amount.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(varsLPG.streamId);
        params.withdrawAmount = boundUint128(params.withdrawAmount, 1, withdrawableAmount);

        varsLPG.isDepleted = params.withdrawAmount == params.create.depositAmount;

        // Load the pre-withdraw token balances.
        varsLPG.initialComptrollerBalanceETH = address(lockup).balance;
        varsLPG.initialLockupBalance = varsLPG.actualLockupBalance;
        varsLPG.initialRecipientBalance = FORK_TOKEN.balanceOf(params.create.recipient);

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.WithdrawFromLockupStream({
            streamId: varsLPG.streamId,
            to: params.create.recipient,
            token: FORK_TOKEN,
            amount: params.withdrawAmount
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: varsLPG.streamId });

        // Make the withdrawal and pay a fee.
        setMsgSender(params.create.recipient);
        vm.deal({ account: params.create.recipient, newBalance: 100 ether });
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: varsLPG.streamId,
            to: params.create.recipient,
            amount: params.withdrawAmount
        });

        // Assert that the stream's status is correct.
        if (varsLPG.isDepleted) {
            varsLPG.expectedStatus = Lockup.Status.DEPLETED;
        } else {
            varsLPG.expectedStatus = Lockup.Status.SETTLED;
        }
        assertEq(lockup.statusOf(varsLPG.streamId), varsLPG.expectedStatus, "post-withdraw stream status");

        // Assert that the withdrawn amount has been updated.
        assertEq(lockup.getWithdrawnAmount(varsLPG.streamId), params.withdrawAmount, "post-withdraw withdrawnAmount");

        // Assert that the aggregate amount has been updated.
        varsLPG.expectedAggregateAmount -= params.withdrawAmount;
        assertEq(lockup.aggregateAmount(FORK_TOKEN), varsLPG.expectedAggregateAmount, "aggregateAmount");

        // Load the post-withdraw token balances.
        balances = getTokenBalances(address(FORK_TOKEN), Solarray.addresses(address(lockup), params.create.recipient));
        varsLPG.actualLockupBalance = balances[0];
        varsLPG.actualRecipientBalance = balances[1];

        // Assert that the contract's balance has been updated.
        expectedLockupBalance = varsLPG.initialLockupBalance - params.withdrawAmount;
        assertEq(varsLPG.actualLockupBalance, expectedLockupBalance, "post-withdraw Lockup balance");

        // Assert that the contract's ETH balance has been updated.
        assertEq(
            address(lockup).balance,
            varsLPG.initialComptrollerBalanceETH + LOCKUP_MIN_FEE_WEI,
            "post-withdraw Lockup balance ETH"
        );

        // Assert that the Recipient's balance has been updated.
        uint256 expectedRecipientBalance = varsLPG.initialRecipientBalance + params.withdrawAmount;
        assertEq(varsLPG.actualRecipientBalance, expectedRecipientBalance, "post-withdraw Recipient balance");

        // Assert that the NFT is still owned by the recipient.
        assertEq(lockup.ownerOf(varsLPG.streamId), params.create.recipient, "post-withdraw NFT owner");
    }

    /// @dev Checklist:
    ///
    /// - It should cancel the stream when time < end time and price < target price
    /// - It should refund the full deposit to the sender
    /// - It should emit a {CancelLockupStream} event
    ///
    /// Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the sender, and recipient
    /// - Multiple values for the deposit amount
    /// - Multiple values for the duration
    /// - Multiple values for the target price
    /// - Oracle mock price below target price
    function testForkFuzz_Cancel(ParamsLPG memory params) external {
        // Bound the fuzzed parameters and load values into `varsLPG`.
        _preCreateStream(params);

        // Create the stream.
        lockup.createWithTimestampsLPG({
            params: params.create,
            unlockParams: LockupPriceGated.UnlockParams(ORACLE, params.targetPrice)
        });

        /*//////////////////////////////////////////////////////////////////////////
                                          CANCEL
        //////////////////////////////////////////////////////////////////////////*/

        // Warp to before the end time so that the stream can be canceled.
        params.warpTimestamp = boundUint40(
            params.warpTimestamp, varsLPG.timestamps.start + 1 seconds, varsLPG.timestamps.end - 1 seconds
        );
        vm.warp({ newTimestamp: params.warpTimestamp });

        // Bound the mock price so that its below the target price.
        params.mockPrice = boundUint128(params.mockPrice, 0, params.targetPrice - 1);

        // Mock the oracle to return the mocked price.
        vm.mockCall(
            address(ORACLE),
            abi.encodeCall(AggregatorV3Interface.latestRoundData, ()),
            abi.encode(uint80(1), int256(uint256(params.mockPrice)), block.timestamp, block.timestamp, uint80(1))
        );

        // Load the pre-cancel token balances.
        uint256[] memory balances = getTokenBalances(
            address(FORK_TOKEN), Solarray.addresses(address(lockup), params.create.sender, params.create.recipient)
        );
        varsLPG.initialLockupBalance = balances[0];
        varsLPG.initialSenderBalance = balances[1];
        varsLPG.initialRecipientBalance = balances[2];

        // For LPG streams that are not settled, the full deposit is refundable.
        varsLPG.senderAmount = lockup.refundableAmountOf(varsLPG.streamId);
        varsLPG.recipientAmount = lockup.withdrawableAmountOf(varsLPG.streamId);

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CancelLockupStream(
            varsLPG.streamId,
            params.create.sender,
            params.create.recipient,
            FORK_TOKEN,
            varsLPG.senderAmount,
            varsLPG.recipientAmount
        );
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: varsLPG.streamId });

        // Cancel the stream.
        setMsgSender(params.create.sender);
        uint128 refundedAmount = lockup.cancel(varsLPG.streamId);

        // Assert that the refunded amount is correct (full deposit for unsettled LPG streams).
        assertEq(refundedAmount, varsLPG.senderAmount, "refundedAmount");
        assertEq(refundedAmount, params.create.depositAmount, "refundedAmount equals deposit");

        // Assert that the stream's status is correct.
        // Since recipientAmount is 0 for unsettled LPG streams, status should be DEPLETED.
        varsLPG.expectedStatus = varsLPG.recipientAmount > 0 ? Lockup.Status.CANCELED : Lockup.Status.DEPLETED;
        assertEq(lockup.statusOf(varsLPG.streamId), varsLPG.expectedStatus, "post-cancel stream status");

        // Assert that the aggregate amount returns to its pre-create value.
        varsLPG.expectedAggregateAmount = varsLPG.initialAggregateAmount;
        assertEq(lockup.aggregateAmount(FORK_TOKEN), varsLPG.expectedAggregateAmount, "aggregateAmount");

        // Load the post-cancel token balances.
        balances = getTokenBalances(
            address(FORK_TOKEN), Solarray.addresses(address(lockup), params.create.sender, params.create.recipient)
        );
        varsLPG.actualLockupBalance = balances[0];
        varsLPG.actualSenderBalance = balances[1];
        varsLPG.actualRecipientBalance = balances[2];

        // Assert that the contract's balance has been updated.
        uint256 expectedLockupBalance = varsLPG.initialLockupBalance - varsLPG.senderAmount;
        assertEq(varsLPG.actualLockupBalance, expectedLockupBalance, "post-cancel Lockup balance");

        // Assert that the Sender's balance has been updated.
        uint256 expectedSenderBalance = varsLPG.initialSenderBalance + varsLPG.senderAmount;
        assertEq(varsLPG.actualSenderBalance, expectedSenderBalance, "post-cancel Sender balance");

        // Assert that the Recipient's balance has not changed.
        assertEq(varsLPG.actualRecipientBalance, varsLPG.initialRecipientBalance, "post-cancel Recipient balance");

        // Assert that the NFT is still owned by the recipient.
        assertEq(lockup.ownerOf(varsLPG.streamId), params.create.recipient, "post-cancel NFT owner");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A pre-create helper function to set up the parameters for the stream creation.
    function _preCreateStream(ParamsLPG memory params) internal {
        checkUsers(params.create.sender, params.create.recipient, address(lockup));

        // Store the pre-create aggregate amount.
        varsLPG.initialAggregateAmount = lockup.aggregateAmount(FORK_TOKEN);

        // Store the pre-create token balances of Lockup and Holder.
        uint256[] memory balances =
            getTokenBalances(address(FORK_TOKEN), Solarray.addresses(address(lockup), forkTokenHolder));
        varsLPG.initialLockupBalance = balances[0];
        initialHolderBalance = uint128(balances[1]);

        // Store the next stream ID.
        varsLPG.streamId = lockup.nextStreamId();

        // Bound the deposit amount.
        params.create.depositAmount = boundUint128(params.create.depositAmount, 1, initialHolderBalance);

        // Calculate timestamps.
        uint40 duration = boundUint40(uint40(uint256(keccak256(abi.encode(params.targetPrice)))), 2 seconds, 52 weeks);
        varsLPG.timestamps =
            Lockup.Timestamps({ start: uint40(block.timestamp), end: uint40(block.timestamp) + duration });
        params.create.timestamps = varsLPG.timestamps;

        // Get the current oracle price and bound the target price above it.
        (, int256 currentPrice,,,) = ORACLE.latestRoundData();

        // Bound the target price.
        uint128 minTargetPrice = uint128(uint256(currentPrice)) + 1;
        uint128 maxTargetPrice = uint128(uint256(currentPrice)) * 3;
        params.targetPrice = boundUint128(params.targetPrice, minTargetPrice, maxTargetPrice);

        // Set fixed values for shape name and token.
        params.create.shape = "Price-gated";
        params.create.token = FORK_TOKEN;

        // Make the stream cancelable so that the cancel tests can be run.
        params.create.cancelable = true;
    }
}
