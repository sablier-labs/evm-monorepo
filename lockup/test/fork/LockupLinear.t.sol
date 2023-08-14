// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Broker, Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { Fork_Test } from "./Fork.t.sol";

abstract contract LockupLinear_Fork_Test is Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset_, address holder_) Fork_Test(asset_, holder_) { }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fork_Test.setUp();

        // Approve {SablierV2LockupLinear} to transfer the asset holder's assets.
        // We use a low-level call to ignore reverts because the asset can have the missing return value bug.
        (bool success,) = address(asset).call(abi.encodeCall(IERC20.approve, (address(lockupLinear), MAX_UINT256)));
        success;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    struct Params {
        Broker broker;
        UD60x18 protocolFee;
        LockupLinear.Range range;
        address recipient;
        address sender;
        uint128 totalAmount;
        uint40 warpTimestamp;
        uint128 withdrawAmount;
    }

    struct Vars {
        // Generic vars
        uint256 actualLockupLinearBalance;
        uint256 actualHolderBalance;
        address actualNFTOwner;
        uint256 actualRecipientBalance;
        Lockup.Status actualStatus;
        uint256[] balances;
        uint256 expectedLockupLinearBalance;
        uint256 expectedHolderBalance;
        address expectedNFTOwner;
        uint256 expectedRecipientBalance;
        Lockup.Status expectedStatus;
        uint256 initialLockupLinearBalance;
        uint256 initialRecipientBalance;
        bool isDepleted;
        bool isSettled;
        uint256 streamId;
        // Create vars
        uint256 actualBrokerBalance;
        uint256 actualNextStreamId;
        uint256 actualProtocolRevenues;
        Lockup.CreateAmounts createAmounts;
        uint256 expectedBrokerBalance;
        uint256 expectedNextStreamId;
        uint256 expectedProtocolRevenues;
        uint256 initialBrokerBalance;
        uint256 initialProtocolRevenues;
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
    /// - Multiple values for the sender, recipient, and broker
    /// - Multiple values for the total amount
    /// - Multiple values for the cliff time and the end time
    /// - Multiple values for the broker fee, including zero
    /// - Multiple values for the protocol fee, including zero
    /// - Multiple values for the withdraw amount, including zero
    /// - Start time in the past
    /// - Start time in the present
    /// - Start time in the future
    /// - Start time lower than and equal to cliff time
    /// - The whole gamut of stream statuses
    function testForkFuzz_LockupLinear_CreateWithdrawCancel(Params memory params) external {
        checkUsers(params.sender, params.recipient, params.broker.account, address(lockupLinear));

        // Bound the parameters.
        uint40 currentTime = getBlockTimestamp();
        params.broker.fee = _bound(params.broker.fee, 0, MAX_FEE);
        params.protocolFee = _bound(params.protocolFee, 0, MAX_FEE);
        params.range.start = boundUint40(params.range.start, currentTime - 1000 seconds, currentTime + 10_000 seconds);
        params.range.cliff = boundUint40(params.range.cliff, params.range.start, params.range.start + 52 weeks);
        params.totalAmount = boundUint128(params.totalAmount, 1, uint128(initialHolderBalance));

        // Bound the end time so that it is always greater than both the current time and the cliff time (this is
        // a requirement of the protocol).
        params.range.end = boundUint40(
            params.range.end,
            (params.range.cliff <= currentTime ? currentTime : params.range.cliff) + 1,
            MAX_UNIX_TIMESTAMP
        );

        // Set the fuzzed protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: asset, newProtocolFee: params.protocolFee });

        // Make the holder the caller.
        changePrank(holder);

        /*//////////////////////////////////////////////////////////////////////////
                                            CREATE
        //////////////////////////////////////////////////////////////////////////*/

        // Load the pre-create protocol revenues.
        Vars memory vars;
        vars.initialProtocolRevenues = lockupLinear.protocolRevenues(asset);

        // Load the pre-create asset balances.
        vars.balances =
            getTokenBalances(address(asset), Solarray.addresses(address(lockupLinear), params.broker.account));
        vars.initialLockupLinearBalance = vars.balances[0];
        vars.initialBrokerBalance = vars.balances[1];

        // Calculate the fee amounts and the deposit amount.
        vars.createAmounts.protocolFee = ud(params.totalAmount).mul(params.protocolFee).intoUint128();
        vars.createAmounts.brokerFee = ud(params.totalAmount).mul(params.broker.fee).intoUint128();
        vars.createAmounts.deposit = params.totalAmount - vars.createAmounts.protocolFee - vars.createAmounts.brokerFee;

        // Expect the relevant event to be emitted.
        vars.streamId = lockupLinear.nextStreamId();
        vm.expectEmit({ emitter: address(lockupLinear) });
        emit CreateLockupLinearStream({
            streamId: vars.streamId,
            funder: holder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: vars.createAmounts,
            asset: asset,
            cancelable: true,
            range: params.range,
            broker: params.broker.account
        });

        // Create the stream.
        lockupLinear.createWithRange(
            LockupLinear.CreateWithRange({
                asset: asset,
                broker: params.broker,
                cancelable: true,
                range: params.range,
                recipient: params.recipient,
                sender: params.sender,
                totalAmount: params.totalAmount
            })
        );

        // Assert that the stream has been created.
        LockupLinear.Stream memory actualStream = lockupLinear.getStream(vars.streamId);
        assertEq(actualStream.amounts, Lockup.Amounts(vars.createAmounts.deposit, 0, 0));
        assertEq(actualStream.asset, asset, "asset");
        assertEq(actualStream.cliffTime, params.range.cliff, "cliffTime");
        assertEq(actualStream.endTime, params.range.end, "endTime");
        assertEq(actualStream.isCancelable, true, "isCancelable");
        assertEq(actualStream.isDepleted, false, "isDepleted");
        assertEq(actualStream.isStream, true, "isStream");
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.startTime, params.range.start, "startTime");
        assertEq(actualStream.wasCanceled, false, "wasCanceled");

        // Assert that the stream's status is correct.
        vars.actualStatus = lockupLinear.statusOf(vars.streamId);
        vars.expectedStatus = params.range.start > currentTime ? Lockup.Status.PENDING : Lockup.Status.STREAMING;
        assertEq(vars.actualStatus, vars.expectedStatus, "post-create stream status");

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = lockupLinear.nextStreamId();
        vars.expectedNextStreamId = vars.streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "post-create nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = lockupLinear.protocolRevenues(asset);
        vars.expectedProtocolRevenues = vars.initialProtocolRevenues + vars.createAmounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "post-create protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = lockupLinear.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "post-create NFT owner");

        // Load the post-create asset balances.
        vars.balances =
            getTokenBalances(address(asset), Solarray.addresses(address(lockupLinear), holder, params.broker.account));
        vars.actualLockupLinearBalance = vars.balances[0];
        vars.actualHolderBalance = vars.balances[1];
        vars.actualBrokerBalance = vars.balances[2];

        // Assert that the LockupLinear contract's balance has been updated.
        vars.expectedLockupLinearBalance =
            vars.initialLockupLinearBalance + vars.createAmounts.deposit + vars.createAmounts.protocolFee;
        assertEq(vars.actualLockupLinearBalance, vars.expectedLockupLinearBalance, "post-create LockupLinear balance");

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
        params.warpTimestamp = boundUint40(params.warpTimestamp, params.range.cliff, params.range.end + 100 seconds);
        vm.warp({ timestamp: params.warpTimestamp });

        // Bound the withdraw amount.
        vars.withdrawableAmount = lockupLinear.withdrawableAmountOf(vars.streamId);
        params.withdrawAmount = boundUint128(params.withdrawAmount, 0, vars.withdrawableAmount);

        // Check if the stream has settled or will get depleted. It is possible for the stream to be just settled
        // and not depleted because the withdraw amount is fuzzed.
        vars.isSettled = lockupLinear.refundableAmountOf(vars.streamId) == 0;
        vars.isDepleted = params.withdrawAmount == vars.createAmounts.deposit;

        // Only run the withdraw tests if the withdraw amount is not zero.
        if (params.withdrawAmount > 0) {
            // Load the pre-withdraw asset balances.
            vars.initialLockupLinearBalance = vars.actualLockupLinearBalance;
            vars.initialRecipientBalance = asset.balanceOf(params.recipient);

            // Expect the relevant events to be emitted.
            vm.expectEmit({ emitter: address(lockupLinear) });
            emit WithdrawFromLockupStream({
                streamId: vars.streamId,
                to: params.recipient,
                amount: params.withdrawAmount
            });
            vm.expectEmit({ emitter: address(lockupLinear) });
            emit MetadataUpdate({ _tokenId: vars.streamId });

            // Make the withdrawal.
            changePrank({ msgSender: params.recipient });
            lockupLinear.withdraw({ streamId: vars.streamId, to: params.recipient, amount: params.withdrawAmount });

            // Assert that the stream's status is correct.
            vars.actualStatus = lockupLinear.statusOf(vars.streamId);
            if (vars.isDepleted) {
                vars.expectedStatus = Lockup.Status.DEPLETED;
            } else if (vars.isSettled) {
                vars.expectedStatus = Lockup.Status.SETTLED;
            } else {
                vars.expectedStatus = Lockup.Status.STREAMING;
            }
            assertEq(vars.actualStatus, vars.expectedStatus, "post-withdraw stream status");

            // Assert that the withdrawn amount has been updated.
            vars.actualWithdrawnAmount = lockupLinear.getWithdrawnAmount(vars.streamId);
            vars.expectedWithdrawnAmount = params.withdrawAmount;
            assertEq(vars.actualWithdrawnAmount, vars.expectedWithdrawnAmount, "post-withdraw withdrawnAmount");

            // Load the post-withdraw asset balances.
            vars.balances =
                getTokenBalances(address(asset), Solarray.addresses(address(lockupLinear), params.recipient));
            vars.actualLockupLinearBalance = vars.balances[0];
            vars.actualRecipientBalance = vars.balances[1];

            // Assert that the contract's balance has been updated.
            vars.expectedLockupLinearBalance = vars.initialLockupLinearBalance - uint256(params.withdrawAmount);
            assertEq(
                vars.actualLockupLinearBalance, vars.expectedLockupLinearBalance, "post-withdraw LockupLinear balance"
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
                address(asset), Solarray.addresses(address(lockupLinear), params.sender, params.recipient)
            );
            vars.initialLockupLinearBalance = vars.balances[0];
            vars.initialSenderBalance = vars.balances[1];
            vars.initialRecipientBalance = vars.balances[2];

            // Expect the relevant events to be emitted.
            vm.expectEmit({ emitter: address(lockupLinear) });
            vars.senderAmount = lockupLinear.refundableAmountOf(vars.streamId);
            vars.recipientAmount = lockupLinear.withdrawableAmountOf(vars.streamId);
            emit CancelLockupStream(
                vars.streamId, params.sender, params.recipient, vars.senderAmount, vars.recipientAmount
            );
            vm.expectEmit({ emitter: address(lockupLinear) });
            emit MetadataUpdate({ _tokenId: vars.streamId });

            // Cancel the stream.
            changePrank({ msgSender: params.sender });
            lockupLinear.cancel(vars.streamId);

            // Assert that the stream's status is correct.
            vars.actualStatus = lockupLinear.statusOf(vars.streamId);
            vars.expectedStatus = vars.recipientAmount > 0 ? Lockup.Status.CANCELED : Lockup.Status.DEPLETED;
            assertEq(vars.actualStatus, vars.expectedStatus, "post-cancel stream status");

            // Load the post-cancel asset balances.
            vars.balances = getTokenBalances(
                address(asset), Solarray.addresses(address(lockupLinear), params.sender, params.recipient)
            );
            vars.actualLockupLinearBalance = vars.balances[0];
            vars.actualSenderBalance = vars.balances[1];
            vars.actualRecipientBalance = vars.balances[2];

            // Assert that the contract's balance has been updated.
            vars.expectedLockupLinearBalance = vars.initialLockupLinearBalance - uint256(vars.senderAmount);
            assertEq(
                vars.actualLockupLinearBalance, vars.expectedLockupLinearBalance, "post-cancel LockupLinear balance"
            );

            // Assert that the Sender's balance has been updated.
            vars.expectedSenderBalance = vars.initialSenderBalance + uint256(vars.senderAmount);
            assertEq(vars.actualSenderBalance, vars.expectedSenderBalance, "post-cancel Sender balance");

            // Assert that the Recipient's balance has not changed.
            vars.expectedRecipientBalance = vars.initialRecipientBalance;
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-cancel Recipient balance");
        }

        // Assert that the NFT has not been burned.
        vars.actualNFTOwner = lockupLinear.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "post-cancel NFT owner");
    }
}
