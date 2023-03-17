// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Broker, Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { Withdraw_Fuzz_Test } from "../../shared/withdraw/withdraw.t.sol";
import { Dynamic_Fuzz_Test } from "../Dynamic.t.sol";

/// @dev This contract complements the tests in {Withdraw_Fuzz_Test} by testing the withdraw function against
/// streams created with fuzzed segments.
contract Withdraw_Dynamic_Fuzz_Test is Dynamic_Fuzz_Test, Withdraw_Fuzz_Test {
    function setUp() public virtual override(Dynamic_Fuzz_Test, Withdraw_Fuzz_Test) {
        Dynamic_Fuzz_Test.setUp();
        Withdraw_Fuzz_Test.setUp();
    }

    struct Params {
        uint128 deposit;
        LockupDynamic.Segment[] segments;
        uint256 timeWarp;
    }

    struct Vars {
        Lockup.Status actualStatus;
        uint256 actualWithdrawnAmount;
        Lockup.CreateAmounts createAmounts;
        Lockup.Status expectedStatus;
        uint256 expectedWithdrawnAmount;
        address funder;
        uint256 streamId;
        uint128 totalAmount;
        uint128 withdrawAmount;
        uint128 withdrawableAmount;
    }

    function test_Withdraw_FuzzedSegments(Params memory params)
        external
        whenStreamActive
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenWithdrawAmountLessThanOrEqualToWithdrawableAmount
        whenCallerSender
        whenCurrentTimeLessThanEndTime
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
        whenNoRecipientReentrancy
    {
        vm.assume(params.segments.length != 0);

        // Make the sender the funder of the stream.
        Vars memory vars;
        vars.funder = users.sender;

        // Fuzz the segment milestones.
        fuzzSegmentMilestones(params.segments, DEFAULT_START_TIME);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        (vars.totalAmount, vars.createAmounts) = fuzzSegmentAmountsAndCalculateCreateAmounts(params.segments);

        // Bound the time warp.
        params.timeWarp = bound(params.timeWarp, 1, params.segments[params.segments.length - 1].milestone);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + params.timeWarp });

        // Mint enough ERC-20 assets to the sender.
        deal({ token: address(DEFAULT_ASSET), to: vars.funder, give: vars.totalAmount });

        // Create the stream with the fuzzed segments.
        vars.streamId = dynamic.createWithMilestones(
            LockupDynamic.CreateWithMilestones({
                sender: users.sender,
                recipient: users.recipient,
                totalAmount: vars.totalAmount,
                asset: DEFAULT_ASSET,
                cancelable: true,
                segments: params.segments,
                startTime: DEFAULT_START_TIME,
                broker: Broker({ account: users.broker, fee: DEFAULT_BROKER_FEE })
            })
        );

        // Bound the withdraw amount.
        vars.withdrawableAmount = dynamic.withdrawableAmountOf(vars.streamId);
        vars.withdrawAmount = boundUint128(vars.withdrawAmount, 1, vars.withdrawableAmount);

        // Expect the ERC-20 assets to be transferred to the recipient.
        expectTransferCall({ to: users.recipient, amount: vars.withdrawAmount });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit();
        emit WithdrawFromLockupStream({ streamId: vars.streamId, to: users.recipient, amount: vars.withdrawAmount });

        // Make the withdrawal.
        dynamic.withdraw({ streamId: vars.streamId, to: users.recipient, amount: vars.withdrawAmount });

        // Assert that the stream has remained active.
        vars.actualStatus = lockup.getStatus(vars.streamId);
        vars.expectedStatus = Lockup.Status.ACTIVE;
        assertEq(vars.actualStatus, vars.expectedStatus);

        // Assert that the withdrawn amount has been updated.
        vars.actualWithdrawnAmount = dynamic.getWithdrawnAmount(vars.streamId);
        vars.expectedWithdrawnAmount = vars.withdrawAmount;
        assertEq(vars.actualWithdrawnAmount, vars.expectedWithdrawnAmount, "withdrawnAmount");
    }
}
