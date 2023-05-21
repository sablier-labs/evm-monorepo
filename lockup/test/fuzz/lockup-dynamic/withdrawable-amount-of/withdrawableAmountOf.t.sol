// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ZERO } from "@prb/math/UD60x18.sol";

import { Broker, LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Fuzz_Test } from "../Dynamic.t.sol";
import { WithdrawableAmountOf_Shared_Test } from
    "../../../shared/lockup/withdrawable-amount-of/withdrawableAmountOf.t.sol";

contract WithdrawableAmountOf_Dynamic_Fuzz_Test is Dynamic_Fuzz_Test, WithdrawableAmountOf_Shared_Test {
    function setUp() public virtual override(Dynamic_Fuzz_Test, WithdrawableAmountOf_Shared_Test) {
        Dynamic_Fuzz_Test.setUp();
        WithdrawableAmountOf_Shared_Test.setUp();

        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: dai, newProtocolFee: ZERO });
        changePrank({ msgSender: users.sender });
    }

    modifier whenStartTimeInThePast() {
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Status streaming
    /// - Status settled
    function testFuzz_WithdrawableAmountOf_NoPreviousWithdrawals(uint40 timeJump) external whenStartTimeInThePast {
        timeJump = boundUint40(timeJump, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() * 2);

        // Create the stream with a custom total amount. The broker fee is disabled so that it doesn't interfere with
        // the calculations.
        LockupDynamic.CreateWithMilestones memory params = defaults.createWithMilestones();
        params.broker = Broker({ account: address(0), fee: ZERO });
        params.totalAmount = defaults.DEPOSIT_AMOUNT();
        uint256 streamId = dynamic.createWithMilestones(params);

        // Simulate the passage of time.
        uint40 currentTime = defaults.START_TIME() + timeJump;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount =
            calculateStreamedAmountForMultipleSegments(currentTime, defaults.segments(), defaults.DEPOSIT_AMOUNT());
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenWithWithdrawals() {
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Multiple withdraw amounts
    /// - Status streaming
    /// - Status settled
    /// - Status depleted
    /// - Withdraw amount equal to deposited amount and not
    function testFuzz_WithdrawableAmountOf(
        uint40 timeJump,
        uint128 withdrawAmount
    )
        external
        whenStartTimeInThePast
        whenWithWithdrawals
    {
        timeJump = boundUint40(timeJump, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() * 2);

        // Define the current time.
        uint40 currentTime = defaults.START_TIME() + timeJump;

        // Bound the withdraw amount.
        uint128 streamedAmount =
            calculateStreamedAmountForMultipleSegments(currentTime, defaults.segments(), defaults.DEPOSIT_AMOUNT());
        withdrawAmount = boundUint128(withdrawAmount, 1, streamedAmount);

        // Create the stream with a custom total amount. The broker fee is disabled so that it doesn't interfere with
        // the calculations.
        LockupDynamic.CreateWithMilestones memory params = defaults.createWithMilestones();
        params.broker = Broker({ account: address(0), fee: ZERO });
        params.totalAmount = defaults.DEPOSIT_AMOUNT();
        uint256 streamId = dynamic.createWithMilestones(params);

        // Simulate the passage of time.
        vm.warp({ timestamp: currentTime });

        // Make the withdrawal.
        dynamic.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount = streamedAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
