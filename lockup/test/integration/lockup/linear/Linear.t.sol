// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Events } from "src/libraries/Events.sol";
import { Status } from "src/types/Enums.sol";
import { Broker, LockupAmounts, CreateLockupAmounts, LockupLinearStream, Segment, Range } from "src/types/Structs.sol";

import { IntegrationTest } from "../../IntegrationTest.t.sol";

abstract contract Linear_Integration_Test is IntegrationTest {
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
        Broker broker;
        uint128 grossDepositAmount;
        UD60x18 protocolFee;
        Range range;
        address recipient;
        address sender;
        uint40 timeWarp;
        uint128 withdrawAmount;
    }

    struct Vars {
        // Generic vars
        uint256 actualLinearBalance;
        uint256 actualHolderBalance;
        address actualNFTOwner;
        uint256 actualRecipientBalance;
        Status actualStatus;
        uint256[] balances;
        uint256 expectedLinearBalance;
        uint256 expectedHolderBalance;
        address expectedNFTOwner;
        uint256 expectedRecipientBalance;
        Status expectedStatus;
        uint256 initialLinearBalance;
        uint256 initialRecipientBalance;
        uint256 streamId;
        // Create vars
        uint256 actualBrokerBalance;
        uint256 actualNextStreamId;
        uint256 actualProtocolRevenues;
        uint128 brokerFeeAmount;
        uint256 expectedBrokerBalance;
        uint256 expectedNextStreamId;
        uint256 expectedProtocolRevenues;
        uint256 initialBrokerBalance;
        uint256 initialProtocolRevenues;
        uint128 netDepositAmount;
        uint128 protocolFeeAmount;
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
    /// - All possible permutations for the sender, recipient, and broker.
    /// - Multiple values for the gross deposit amount.
    /// - Start time in the past, present and future.
    /// - Start time lower than and equal to cliff time.
    /// - Cliff time lower than and equal to stop time
    /// - Multiple values for the broker fee, including zero.
    /// - Multiple values for the protocol fee, including zero.
    /// - Multiple values for the withdraw amount, including zero.
    function testForkFuzz_Linear_CreateWithdrawCancel(Params memory params) external {
        vm.assume(params.sender != address(0) && params.recipient != address(0) && params.broker.addr != address(0));
        vm.assume(
            params.sender != params.recipient &&
                params.sender != params.broker.addr &&
                params.recipient != params.broker.addr
        );
        vm.assume(params.sender != holder && params.recipient != holder && params.broker.addr != holder);
        vm.assume(
            params.sender != address(linear) &&
                params.recipient != address(linear) &&
                params.broker.addr != address(linear)
        );
        vm.assume(params.grossDepositAmount != 0 && params.grossDepositAmount <= initialHolderBalance);
        vm.assume(params.range.start <= params.range.cliff && params.range.cliff <= params.range.stop);
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        params.protocolFee = bound(params.protocolFee, 0, DEFAULT_MAX_FEE);

        // Set the fuzzed protocol fee.
        changePrank({ who: users.admin });
        comptroller.setProtocolFee({ asset: asset, newProtocolFee: params.protocolFee });

        // Make the holder the caller in the rest of the test.
        changePrank(holder);

        /*//////////////////////////////////////////////////////////////////////////
                                            CREATE
        //////////////////////////////////////////////////////////////////////////*/

        // Load the pre-create protocol revenues.
        Vars memory vars;
        vars.initialProtocolRevenues = linear.getProtocolRevenues(asset);

        // Load the pre-create asset balances.
        vars.balances = getTokenBalances(address(asset), Solarray.addresses(address(linear), params.broker.addr));
        vars.initialLinearBalance = vars.balances[0];
        vars.initialBrokerBalance = vars.balances[1];

        // Calculate the fee amounts and the net deposit amount.
        vars.protocolFeeAmount = ud(params.grossDepositAmount).mul(params.protocolFee).intoUint128();
        vars.brokerFeeAmount = ud(params.grossDepositAmount).mul(params.broker.fee).intoUint128();
        vars.netDepositAmount = params.grossDepositAmount - vars.protocolFeeAmount - vars.brokerFeeAmount;

        // Expect a {CreateLockupLinearStream} event to be emitted.
        vars.streamId = linear.nextStreamId();
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLockupLinearStream({
            streamId: vars.streamId,
            funder: holder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: CreateLockupAmounts({
                netDeposit: vars.netDepositAmount,
                protocolFee: vars.protocolFeeAmount,
                brokerFee: vars.brokerFeeAmount
            }),
            asset: asset,
            cancelable: true,
            range: params.range,
            broker: params.broker.addr
        });

        // Create the stream.
        linear.createWithRange({
            sender: params.sender,
            recipient: params.recipient,
            grossDepositAmount: params.grossDepositAmount,
            asset: asset,
            cancelable: true,
            range: params.range,
            broker: params.broker
        });

        // Assert that the stream was created.
        LockupLinearStream memory actualStream = linear.getStream(vars.streamId);
        assertEq(actualStream.amounts, LockupAmounts({ deposit: vars.netDepositAmount, withdrawn: 0 }));
        assertEq(actualStream.asset, asset, "asset");
        assertEq(actualStream.isCancelable, true, "isCancelable");
        assertEq(actualStream.range, params.range);
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.status, Status.ACTIVE);

        // Assert that the next stream id was bumped.
        vars.actualNextStreamId = linear.nextStreamId();
        vars.expectedNextStreamId = vars.streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee was recorded.
        vars.actualProtocolRevenues = linear.getProtocolRevenues(asset);
        vars.expectedProtocolRevenues = vars.initialProtocolRevenues + vars.protocolFeeAmount;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT was minted.
        vars.actualNFTOwner = linear.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner after create");

        // Load the post-create asset balances.
        vars.balances = getTokenBalances(
            address(asset),
            Solarray.addresses(address(linear), holder, params.broker.addr)
        );
        vars.actualLinearBalance = vars.balances[0];
        vars.actualHolderBalance = vars.balances[1];
        vars.actualBrokerBalance = vars.balances[2];

        // Assert that the linear contract's balance was updated.
        vars.expectedLinearBalance = vars.initialLinearBalance + vars.netDepositAmount + vars.protocolFeeAmount;
        assertEq(vars.actualLinearBalance, vars.expectedLinearBalance, "post-create linear contract balance");

        // Assert that the holder's balance was updated.
        vars.expectedHolderBalance = initialHolderBalance - params.grossDepositAmount;
        assertEq(vars.actualHolderBalance, vars.expectedHolderBalance, "post-create holder balance");

        // Assert that the broker's balance was updated.
        vars.expectedBrokerBalance = vars.initialBrokerBalance + vars.brokerFeeAmount;
        assertEq(vars.actualBrokerBalance, vars.expectedBrokerBalance, "post-create broker balance");

        /*//////////////////////////////////////////////////////////////////////////
                                          WITHDRAW
        //////////////////////////////////////////////////////////////////////////*/

        // Warp into the future.
        params.timeWarp = boundUint40(params.timeWarp, params.range.cliff, params.range.stop);
        vm.warp({ timestamp: params.timeWarp });

        // Bound the withdraw amount.
        vars.withdrawableAmount = linear.getWithdrawableAmount(vars.streamId);
        params.withdrawAmount = boundUint128(params.withdrawAmount, 0, vars.withdrawableAmount);

        // Only run the withdraw tests if the withdraw amount is not zero.
        if (params.withdrawAmount > 0) {
            // Load the pre-withdraw asset balances.
            vars.initialLinearBalance = vars.actualLinearBalance;
            vars.initialRecipientBalance = asset.balanceOf(params.recipient);

            // Expect a {WithdrawFromLockupStream} event to be emitted.
            vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
            emit Events.WithdrawFromLockupStream({
                streamId: vars.streamId,
                to: params.recipient,
                amount: params.withdrawAmount
            });

            // Make the withdrawal.
            changePrank(params.recipient);
            linear.withdraw({ streamId: vars.streamId, to: params.recipient, amount: params.withdrawAmount });

            // Assert that the withdrawn amount was updated.
            vars.actualWithdrawnAmount = linear.getWithdrawnAmount(vars.streamId);
            vars.expectedWithdrawnAmount = params.withdrawAmount;
            assertEq(vars.actualWithdrawnAmount, vars.expectedWithdrawnAmount, "withdrawnAmount");

            // Load the post-withdraw asset balances.
            vars.balances = getTokenBalances(address(asset), Solarray.addresses(address(linear), params.recipient));
            vars.actualLinearBalance = vars.balances[0];
            vars.actualRecipientBalance = vars.balances[1];

            // Assert that the contract's balance was updated.
            vars.expectedLinearBalance = vars.initialLinearBalance - uint256(params.withdrawAmount);
            assertEq(vars.actualLinearBalance, vars.expectedLinearBalance, "post-withdraw linear contract balance");

            // Assert that the recipient's balance was updated.
            vars.expectedRecipientBalance = vars.initialRecipientBalance + uint256(params.withdrawAmount);
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-withdraw recipient balance");
        }

        /*//////////////////////////////////////////////////////////////////////////
                                          CANCEL
        //////////////////////////////////////////////////////////////////////////*/

        // Only run the cancel tests if the stream has not been depleted.
        if (params.withdrawAmount != vars.netDepositAmount) {
            // Load the pre-cancel asset balances.
            vars.balances = getTokenBalances(
                address(asset),
                Solarray.addresses(address(linear), params.sender, params.recipient)
            );
            vars.initialLinearBalance = vars.balances[0];
            vars.initialSenderBalance = vars.balances[1];
            vars.initialRecipientBalance = vars.balances[2];

            // Expect a {CancelLockupStream} event to be emitted.
            vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
            vars.senderAmount = linear.getReturnableAmount(vars.streamId);
            vars.recipientAmount = linear.getWithdrawableAmount(vars.streamId);
            emit Events.CancelLockupStream(
                vars.streamId,
                params.sender,
                params.recipient,
                vars.senderAmount,
                vars.recipientAmount
            );

            // Cancel the stream.
            changePrank(params.sender);
            linear.cancel(vars.streamId);

            // Assert that the stream was marked as canceled.
            vars.actualStatus = linear.getStatus(vars.streamId);
            vars.expectedStatus = Status.CANCELED;
            assertEq(vars.actualStatus, vars.expectedStatus, "status after cancel");

            // Assert that the NFT was not burned.
            vars.actualNFTOwner = linear.ownerOf({ tokenId: vars.streamId });
            vars.expectedNFTOwner = params.recipient;
            assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner after cancel");

            // Load the post-cancel asset balances.
            vars.balances = getTokenBalances(
                address(asset),
                Solarray.addresses(address(linear), params.sender, params.recipient)
            );
            vars.actualLinearBalance = vars.balances[0];
            vars.actualSenderBalance = vars.balances[1];
            vars.actualRecipientBalance = vars.balances[2];

            // Assert that the contract's balance was updated.
            vars.expectedLinearBalance =
                vars.initialLinearBalance -
                uint256(vars.senderAmount) -
                uint256(vars.recipientAmount);
            assertEq(vars.actualLinearBalance, vars.expectedLinearBalance, "post-cancel linear contract balance");

            // Assert that the recipient's balance was updated.
            vars.expectedSenderBalance = vars.initialSenderBalance + uint256(vars.senderAmount);
            assertEq(vars.actualSenderBalance, vars.expectedSenderBalance, "post-cancel sender balance");

            // Assert that the recipient's balance was updated.
            vars.expectedRecipientBalance = vars.initialRecipientBalance + uint256(vars.recipientAmount);
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-cancel recipient balance");
        }
        // Otherwise, assert that the stream was marked as depleted.
        else {
            vars.actualStatus = linear.getStatus(vars.streamId);
            vars.expectedStatus = Status.DEPLETED;
            assertEq(vars.actualStatus, vars.expectedStatus, "status after full withdraw");
        }
    }
}
