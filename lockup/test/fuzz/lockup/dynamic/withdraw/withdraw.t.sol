// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

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
        address to;
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
        uint40 totalDuration;
        uint128 withdrawAmount;
        uint128 withdrawableAmount;
    }

    /// @dev Checklist:
    /// - it should make the withdrawal
    /// - it should update the withdrawn amount
    /// - it should ignore the revert
    function test_Withdraw_FuzzedSegments(Params memory params)
        external
        whenStreamActive
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenWithdrawAmountNotGreaterThanWithdrawableAmount
    {
        vm.assume(params.segments.length != 0);
        vm.assume(params.to != address(0));

        // Make the sender the stream's funder.
        Vars memory vars;
        vars.funder = users.sender;

        // Fuzz the segment milestones.
        fuzzSegmentMilestones(params.segments, DEFAULT_START_TIME);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        (vars.totalAmount, vars.createAmounts) = fuzzSegmentAmountsAndCalculateCreateAmounts(params.segments);

        // Bound the time warp.
        vars.totalDuration = params.segments[params.segments.length - 1].milestone - DEFAULT_START_TIME;
        params.timeWarp = bound(params.timeWarp, 1, vars.totalDuration);

        // Mint enough assets to the sender.
        deal({ token: address(DEFAULT_ASSET), to: vars.funder, give: vars.totalAmount });

        // Make the sender the caller.
        changePrank({ msgSender: users.sender });

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

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + params.timeWarp });

        // Query the withdrawable amount.
        vars.withdrawableAmount = dynamic.withdrawableAmountOf(vars.streamId);

        // Halt the test if the withdraw amount is zero.
        if (vars.withdrawableAmount == 0) {
            return;
        }

        // Bound the withdraw amount.
        vars.withdrawAmount = boundUint128(vars.withdrawAmount, 1, vars.withdrawableAmount);

        // Expect the assets to be transferred to the fuzzed `to` address.
        expectTransferCall({ to: params.to, amount: vars.withdrawAmount });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: vars.streamId, to: params.to, amount: vars.withdrawAmount });

        // Make the recipient the caller.
        changePrank({ msgSender: users.recipient });

        // Make the withdrawal.
        dynamic.withdraw({ streamId: vars.streamId, to: params.to, amount: vars.withdrawAmount });

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
