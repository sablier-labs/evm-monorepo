// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Broker, Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { Fork_Test } from "../../Fork.t.sol";

abstract contract Linear_Fork_Test is Fork_Test {
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
        (bool success,) = address(asset).call(abi.encodeCall(IERC20.approve, (address(linear), UINT256_MAX)));
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
        uint40 timeWarp;
        uint128 totalAmount;
        uint128 withdrawAmount;
    }

    struct Vars {
        // Generic vars
        uint256 actualLinearContractBalance;
        uint256 actualHolderBalance;
        address actualNFTOwner;
        uint256 actualRecipientBalance;
        Lockup.Status actualStatus;
        uint256[] balances;
        uint256 expectedLinearContractBalance;
        uint256 expectedHolderBalance;
        address expectedNFTOwner;
        uint256 expectedRecipientBalance;
        Lockup.Status expectedStatus;
        uint256 initialLinearContractBalance;
        uint256 initialRecipientBalance;
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

    /// @dev it should:
    ///
    /// - Perform all expected ERC-20 transfers.
    /// - Create the stream.
    /// - Bump the next stream id.
    /// - Record the protocol fee.
    /// - Mint the NFT.
    /// - Emit a {CreateLockupLinearStream} event.
    /// - Make a withdrawal.
    /// - Emit a {WithdrawFromLockupStream} event.
    /// - Cancel the stream.
    /// - Emit a {CancelLockupStream} event.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Multiple values for the the sender, recipient, and broker.
    /// - Multiple values for the total amount.
    /// - Start time in the past, present and future.
    /// - Start time lower than and equal to cliff time.
    /// - Multiple values for the cliff time and the stop time.
    /// - Multiple values for the broker fee, including zero.
    /// - Multiple values for the protocol fee, including zero.
    /// - Multiple values for the withdraw amount, including zero.
    function testForkFuzz_Linear_CreateWithdrawCancel(Params memory params) external {
        checkUsers(params.sender, params.recipient, params.broker.account, address(linear));
        params.broker.fee = bound(params.broker.fee, 0, MAX_FEE);
        params.range.start = boundUint40(
            params.range.start, uint40(block.timestamp - 1000 seconds), uint40(block.timestamp + 10_000 seconds)
        );
        params.range.cliff = boundUint40(params.range.cliff, params.range.start, params.range.start + 52 weeks);
        params.range.end = boundUint40(params.range.end, params.range.cliff + 1, MAX_UNIX_TIMESTAMP);
        params.protocolFee = bound(params.protocolFee, 0, MAX_FEE);
        params.totalAmount = boundUint128(params.totalAmount, 1, uint128(initialHolderBalance));

        // Set the fuzzed protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: asset, newProtocolFee: params.protocolFee });

        // Make the holder the caller in the rest of the test.
        changePrank(holder);

        /*//////////////////////////////////////////////////////////////////////////
                                            CREATE
        //////////////////////////////////////////////////////////////////////////*/

        // Load the pre-create protocol revenues.
        Vars memory vars;
        vars.initialProtocolRevenues = linear.protocolRevenues(asset);

        // Load the pre-create asset balances.
        vars.balances = getTokenBalances(address(asset), Solarray.addresses(address(linear), params.broker.account));
        vars.initialLinearContractBalance = vars.balances[0];
        vars.initialBrokerBalance = vars.balances[1];

        // Calculate the fee amounts and the deposit amount.
        vars.createAmounts.protocolFee = ud(params.totalAmount).mul(params.protocolFee).intoUint128();
        vars.createAmounts.brokerFee = ud(params.totalAmount).mul(params.broker.fee).intoUint128();
        vars.createAmounts.deposit = params.totalAmount - vars.createAmounts.protocolFee - vars.createAmounts.brokerFee;

        // Expect a {CreateLockupLinearStream} event to be emitted.
        vars.streamId = linear.nextStreamId();
        vm.expectEmit({ emitter: address(linear) });
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
        linear.createWithRange(
            LockupLinear.CreateWithRange({
                sender: params.sender,
                recipient: params.recipient,
                totalAmount: params.totalAmount,
                asset: asset,
                cancelable: true,
                range: params.range,
                broker: params.broker
            })
        );

        // Assert that the stream has been created.
        LockupLinear.Stream memory actualStream = linear.getStream(vars.streamId);
        assertEq(actualStream.amounts, Lockup.Amounts({ deposit: vars.createAmounts.deposit, withdrawn: 0 }));
        assertEq(actualStream.asset, asset, "asset");
        assertEq(actualStream.cliffTime, params.range.cliff, "cliffTime");
        assertEq(actualStream.endTime, params.range.end, "endTime");
        assertEq(actualStream.isCancelable, true, "isCancelable");
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.startTime, params.range.start, "startTime");
        assertEq(actualStream.status, Lockup.Status.ACTIVE);

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = linear.nextStreamId();
        vars.expectedNextStreamId = vars.streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = linear.protocolRevenues(asset);
        vars.expectedProtocolRevenues = vars.initialProtocolRevenues + vars.createAmounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = linear.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner after create");

        // Load the post-create asset balances.
        vars.balances =
            getTokenBalances(address(asset), Solarray.addresses(address(linear), holder, params.broker.account));
        vars.actualLinearContractBalance = vars.balances[0];
        vars.actualHolderBalance = vars.balances[1];
        vars.actualBrokerBalance = vars.balances[2];

        // Assert that the linear contract's balance has been updated.
        vars.expectedLinearContractBalance =
            vars.initialLinearContractBalance + vars.createAmounts.deposit + vars.createAmounts.protocolFee;
        assertEq(
            vars.actualLinearContractBalance, vars.expectedLinearContractBalance, "post-create linear contract balance"
        );

        // Assert that the holder's balance has been updated.
        vars.expectedHolderBalance = initialHolderBalance - params.totalAmount;
        assertEq(vars.actualHolderBalance, vars.expectedHolderBalance, "post-create holder balance");

        // Assert that the broker's balance has been updated.
        vars.expectedBrokerBalance = vars.initialBrokerBalance + vars.createAmounts.brokerFee;
        assertEq(vars.actualBrokerBalance, vars.expectedBrokerBalance, "post-create broker balance");

        /*//////////////////////////////////////////////////////////////////////////
                                          WITHDRAW
        //////////////////////////////////////////////////////////////////////////*/

        // Warp into the future.
        params.timeWarp = boundUint40(params.timeWarp, params.range.cliff, params.range.end);
        vm.warp({ timestamp: params.timeWarp });

        // Bound the withdraw amount.
        vars.withdrawableAmount = linear.withdrawableAmountOf(vars.streamId);
        params.withdrawAmount = boundUint128(params.withdrawAmount, 0, vars.withdrawableAmount);

        // Only run the withdraw tests if the withdraw amount is not zero.
        if (params.withdrawAmount > 0) {
            // Load the pre-withdraw asset balances.
            vars.initialLinearContractBalance = vars.actualLinearContractBalance;
            vars.initialRecipientBalance = asset.balanceOf(params.recipient);

            // Expect a {WithdrawFromLockupStream} event to be emitted.
            vm.expectEmit({ emitter: address(linear) });
            emit WithdrawFromLockupStream({
                streamId: vars.streamId,
                to: params.recipient,
                amount: params.withdrawAmount
            });

            // Make the withdrawal.
            changePrank(params.recipient);
            linear.withdraw({ streamId: vars.streamId, to: params.recipient, amount: params.withdrawAmount });

            // Assert that the withdrawn amount has been updated.
            vars.actualWithdrawnAmount = linear.getWithdrawnAmount(vars.streamId);
            vars.expectedWithdrawnAmount = params.withdrawAmount;
            assertEq(vars.actualWithdrawnAmount, vars.expectedWithdrawnAmount, "withdrawnAmount");

            // Load the post-withdraw asset balances.
            vars.balances = getTokenBalances(address(asset), Solarray.addresses(address(linear), params.recipient));
            vars.actualLinearContractBalance = vars.balances[0];
            vars.actualRecipientBalance = vars.balances[1];

            // Assert that the contract's balance has been updated.
            vars.expectedLinearContractBalance = vars.initialLinearContractBalance - uint256(params.withdrawAmount);
            assertEq(
                vars.actualLinearContractBalance,
                vars.expectedLinearContractBalance,
                "post-withdraw linear contract balance"
            );

            // Assert that the recipient's balance has been updated.
            vars.expectedRecipientBalance = vars.initialRecipientBalance + uint256(params.withdrawAmount);
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-withdraw recipient balance");
        }

        /*//////////////////////////////////////////////////////////////////////////
                                          CANCEL
        //////////////////////////////////////////////////////////////////////////*/

        // Only run the cancel tests if the stream has not been depleted.
        if (params.withdrawAmount != vars.createAmounts.deposit) {
            // Load the pre-cancel asset balances.
            vars.balances =
                getTokenBalances(address(asset), Solarray.addresses(address(linear), params.sender, params.recipient));
            vars.initialLinearContractBalance = vars.balances[0];
            vars.initialSenderBalance = vars.balances[1];
            vars.initialRecipientBalance = vars.balances[2];

            // Expect a {CancelLockupStream} event to be emitted.
            vm.expectEmit({ emitter: address(linear) });
            vars.senderAmount = linear.returnableAmountOf(vars.streamId);
            vars.recipientAmount = linear.withdrawableAmountOf(vars.streamId);
            emit CancelLockupStream(
                vars.streamId, params.sender, params.recipient, vars.senderAmount, vars.recipientAmount
            );

            // Cancel the stream.
            changePrank(params.sender);
            linear.cancel(vars.streamId);

            // Assert that the stream has been marked as canceled.
            vars.actualStatus = linear.getStatus(vars.streamId);
            vars.expectedStatus = Lockup.Status.CANCELED;
            assertEq(vars.actualStatus, vars.expectedStatus, "status after cancel");

            // Assert that the NFT has not been burned.
            vars.actualNFTOwner = linear.ownerOf({ tokenId: vars.streamId });
            vars.expectedNFTOwner = params.recipient;
            assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner after cancel");

            // Load the post-cancel asset balances.
            vars.balances =
                getTokenBalances(address(asset), Solarray.addresses(address(linear), params.sender, params.recipient));
            vars.actualLinearContractBalance = vars.balances[0];
            vars.actualSenderBalance = vars.balances[1];
            vars.actualRecipientBalance = vars.balances[2];

            // Assert that the contract's balance has been updated.
            vars.expectedLinearContractBalance =
                vars.initialLinearContractBalance - uint256(vars.senderAmount) - uint256(vars.recipientAmount);
            assertEq(
                vars.actualLinearContractBalance,
                vars.expectedLinearContractBalance,
                "post-cancel linear contract balance"
            );

            // Assert that the recipient's balance has been updated.
            vars.expectedSenderBalance = vars.initialSenderBalance + uint256(vars.senderAmount);
            assertEq(vars.actualSenderBalance, vars.expectedSenderBalance, "post-cancel sender balance");

            // Assert that the recipient's balance has been updated.
            vars.expectedRecipientBalance = vars.initialRecipientBalance + uint256(vars.recipientAmount);
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-cancel recipient balance");
        }
        // Otherwise, assert that the stream has been marked as depleted.
        else {
            vars.actualStatus = linear.getStatus(vars.streamId);
            vars.expectedStatus = Lockup.Status.DEPLETED;
            assertEq(vars.actualStatus, vars.expectedStatus, "status after full withdraw");
        }
    }
}
