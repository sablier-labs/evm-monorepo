// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Events } from "src/libraries/Events.sol";
import { Broker, Lockup, LockupPro } from "src/types/DataTypes.sol";

import { E2e_Test } from "../../E2eTest.t.sol";

abstract contract Pro_E2e_Test is E2e_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset_, address holder_) E2e_Test(asset_, holder_) {}

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        E2e_Test.setUp();

        // Approve the {SablierV2LockupPro} contract to transfer the holder's ERC-20 assets.
        // We use a low-level call to ignore reverts because the asset can have the missing return value bug.
        (bool success, ) = address(asset).call(abi.encodeCall(IERC20.approve, (address(pro), UINT256_MAX)));
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
        uint40 timeWarp;
        LockupPro.Segment[] segments;
        uint128 withdrawAmount;
    }

    struct Vars {
        // Generic vars
        address actualNFTOwner;
        uint256 actualProBalance;
        uint256 actualRecipientBalance;
        Lockup.Status actualStatus;
        uint256[] balances;
        address expectedNFTOwner;
        uint256 expectedProBalance;
        uint256 expectedRecipientBalance;
        Lockup.Status expectedStatus;
        uint256 initialProBalance;
        uint256 initialRecipientBalance;
        uint256 streamId;
        // Create vars
        uint256 actualBrokerBalance;
        uint256 actualHolderBalance;
        uint256 actualNextStreamId;
        uint256 actualProtocolRevenues;
        Lockup.CreateAmounts amounts;
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

    /// @dev it should:
    ///
    /// - Perform all expected ERC-20 transfers.
    /// - Create the stream.
    /// - Bump the next stream id.
    /// - Record the protocol fee.
    /// - Mint the NFT.
    /// - Emit a {CreateLockupProStream} event.
    /// - Make a withdrawal.
    /// - Update the withdrawn amounts.
    /// - Emit a {WithdrawFromLockupStream} event.
    /// - Cancel the stream.
    /// - Emit a {CancelLockupStream} event.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Multiple values for the funder, recipient, sender, and broker.
    /// - Multiple values for the total amount.
    /// - Start time in the past, present and future.
    /// - Start time equal and not equal to the first segment milestone.
    /// - Multiple values for the broker fee, including zero.
    /// - Multiple values for the protocol fee, including zero.
    /// - Multiple values for the withdraw amount, including zero.
    function testForkFuzz_Pro_CreateWithdrawCancel(Params memory params) external {
        checkUsers(params.sender, params.recipient, params.broker.account, address(pro));
        vm.assume(params.segments.length != 0);
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        params.protocolFee = bound(params.protocolFee, 0, DEFAULT_MAX_FEE);
        params.startTime = boundUint40(params.startTime, 0, DEFAULT_START_TIME);

        // Fuzz the segment milestones.
        fuzzSegmentMilestones(params.segments, params.startTime);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        Vars memory vars;
        (vars.totalAmount, vars.amounts) = fuzzSegmentAmountsAndCalculateCreateAmounts({
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
        vars.initialProtocolRevenues = pro.getProtocolRevenues(asset);

        // Load the pre-create asset balances.
        vars.balances = getTokenBalances(address(asset), Solarray.addresses(address(pro), params.broker.account));
        vars.initialProBalance = vars.balances[0];
        vars.initialBrokerBalance = vars.balances[1];

        // Expect a {CreateLockupProStream} event to be emitted.
        vars.streamId = pro.nextStreamId();
        expectEmit();
        LockupPro.Range memory range = LockupPro.Range({
            start: params.startTime,
            end: params.segments[params.segments.length - 1].milestone
        });
        emit Events.CreateLockupProStream({
            streamId: vars.streamId,
            funder: holder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: vars.amounts,
            asset: asset,
            cancelable: true,
            segments: params.segments,
            range: range,
            broker: params.broker.account
        });

        // Create the stream.
        pro.createWithMilestones(
            LockupPro.CreateWithMilestones({
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
        LockupPro.Stream memory actualStream = pro.getStream(vars.streamId);
        assertEq(actualStream.amounts, Lockup.Amounts({ deposit: vars.amounts.deposit, withdrawn: 0 }));
        assertEq(actualStream.asset, asset, "asset");
        assertEq(actualStream.endTime, range.end, "endTime");
        assertEq(actualStream.isCancelable, true, "isCancelable");
        assertEq(actualStream.segments, params.segments);
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.startTime, range.start, "startTime");
        assertEq(actualStream.status, Lockup.Status.ACTIVE);

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = pro.nextStreamId();
        vars.expectedNextStreamId = vars.streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = pro.getProtocolRevenues(asset);
        vars.expectedProtocolRevenues = vars.initialProtocolRevenues + vars.amounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = pro.ownerOf({ tokenId: vars.streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");

        // Load the post-create asset balances.
        vars.balances = getTokenBalances(
            address(asset),
            Solarray.addresses(address(pro), holder, params.broker.account)
        );
        vars.actualProBalance = vars.balances[0];
        vars.actualHolderBalance = vars.balances[1];
        vars.actualBrokerBalance = vars.balances[2];

        // Assert that the pro contract's balance has been updated.
        vars.expectedProBalance = vars.initialProBalance + vars.amounts.deposit + vars.amounts.protocolFee;
        assertEq(vars.actualProBalance, vars.expectedProBalance, "post-create pro contract balance");

        // Assert that the holder's balance has been updated.
        vars.expectedHolderBalance = initialHolderBalance - vars.totalAmount;
        assertEq(vars.actualHolderBalance, vars.expectedHolderBalance, "post-create holder balance");

        // Assert that the broker's balance has been updated.
        vars.expectedBrokerBalance = vars.initialBrokerBalance + vars.amounts.brokerFee;
        assertEq(vars.actualBrokerBalance, vars.expectedBrokerBalance, "post-create broker balance");

        /*//////////////////////////////////////////////////////////////////////////
                                          WITHDRAW
        //////////////////////////////////////////////////////////////////////////*/

        // Warp into the future.
        params.timeWarp = boundUint40(params.timeWarp, params.startTime, DEFAULT_END_TIME);
        vm.warp({ timestamp: params.timeWarp });

        // Bound the withdraw amount.
        vars.withdrawableAmount = pro.withdrawableAmountOf(vars.streamId);
        params.withdrawAmount = boundUint128(params.withdrawAmount, 0, vars.withdrawableAmount);

        // Only run the withdraw tests if the withdraw amount is not zero.
        if (params.withdrawAmount > 0) {
            // Load the pre-withdraw asset balances.
            vars.initialProBalance = vars.actualProBalance;
            vars.initialRecipientBalance = asset.balanceOf(params.recipient);

            // Expect a {WithdrawFromLockupStream} event to be emitted.
            expectEmit();
            emit Events.WithdrawFromLockupStream({
                streamId: vars.streamId,
                to: params.recipient,
                amount: params.withdrawAmount
            });

            // Make the withdrawal.
            changePrank(params.recipient);
            pro.withdraw({ streamId: vars.streamId, to: params.recipient, amount: params.withdrawAmount });

            // Assert that the withdrawn amount has been updated.
            vars.actualWithdrawnAmount = pro.getWithdrawnAmount(vars.streamId);
            vars.expectedWithdrawnAmount = params.withdrawAmount;
            assertEq(vars.actualWithdrawnAmount, vars.expectedWithdrawnAmount, "withdrawnAmount");

            // Load the post-withdraw asset balances.
            vars.balances = getTokenBalances(address(asset), Solarray.addresses(address(pro), params.recipient));
            vars.actualProBalance = vars.balances[0];
            vars.actualRecipientBalance = vars.balances[1];

            // Assert that the contract's balance has been updated.
            vars.expectedProBalance = vars.initialProBalance - uint256(params.withdrawAmount);
            assertEq(vars.actualProBalance, vars.expectedProBalance, "post-withdraw pro contract balance");

            // Assert that the recipient's balance has been updated.
            vars.expectedRecipientBalance = vars.initialRecipientBalance + uint256(params.withdrawAmount);
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-withdraw recipient balance");
        }

        /*//////////////////////////////////////////////////////////////////////////
                                          CANCEL
        //////////////////////////////////////////////////////////////////////////*/

        // Only run the cancel tests if the stream has not been depleted.
        if (params.withdrawAmount != vars.amounts.deposit) {
            // Load the pre-cancel asset balances.
            vars.balances = getTokenBalances(
                address(asset),
                Solarray.addresses(address(pro), params.sender, params.recipient)
            );
            vars.initialProBalance = vars.balances[0];
            vars.initialSenderBalance = vars.balances[1];
            vars.initialRecipientBalance = vars.balances[2];

            // Expect a {CancelLockupStream} event to be emitted.
            expectEmit();
            vars.senderAmount = pro.returnableAmountOf(vars.streamId);
            vars.recipientAmount = pro.withdrawableAmountOf(vars.streamId);
            emit Events.CancelLockupStream(
                vars.streamId,
                params.sender,
                params.recipient,
                vars.senderAmount,
                vars.recipientAmount
            );

            // Cancel the stream.
            changePrank(params.sender);
            pro.cancel(vars.streamId);

            // Assert that the stream has been marked as canceled.
            vars.actualStatus = pro.getStatus(vars.streamId);
            vars.expectedStatus = Lockup.Status.CANCELED;
            assertEq(vars.actualStatus, vars.expectedStatus, "status after cancel");

            // Assert that the NFT has not been burned.
            vars.actualNFTOwner = pro.ownerOf({ tokenId: vars.streamId });
            vars.expectedNFTOwner = params.recipient;
            assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner after cancel");

            // Load the post-cancel asset balances.
            vars.balances = getTokenBalances(
                address(asset),
                Solarray.addresses(address(pro), params.sender, params.recipient)
            );
            vars.actualProBalance = vars.balances[0];
            vars.actualSenderBalance = vars.balances[1];
            vars.actualRecipientBalance = vars.balances[2];

            // Assert that the contract's balance has been updated.
            vars.expectedProBalance =
                vars.initialProBalance -
                uint256(vars.senderAmount) -
                uint256(vars.recipientAmount);
            assertEq(vars.actualProBalance, vars.expectedProBalance, "post-cancel pro contract balance");

            // Assert that the recipient's balance has been updated.
            vars.expectedSenderBalance = vars.initialSenderBalance + uint256(vars.senderAmount);
            assertEq(vars.actualSenderBalance, vars.expectedSenderBalance, "post-cancel sender balance");

            // Assert that the recipient's balance has been updated.
            vars.expectedRecipientBalance = vars.initialRecipientBalance + uint256(vars.recipientAmount);
            assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "post-cancel recipient balance");
        }
        // Otherwise, assert that the stream has been marked as depleted.
        else {
            vars.actualStatus = pro.getStatus(vars.streamId);
            vars.expectedStatus = Lockup.Status.DEPLETED;
            assertEq(vars.actualStatus, vars.expectedStatus, "status after full withdraw");
        }
    }
}
