// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud21x18 } from "@prb/math/src/UD21x18.sol";
import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract WithdrawMultiple_Delay_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev Checklist:
    /// - It should test multiple withdrawals from the stream using `withdrawMax`.
    /// - It should assert that the actual withdrawn amount is less than the desired amount.
    /// - It should check that stream delay and deviation are within acceptable limits for realistic values of rps.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed for USDC:
    /// - Multiple values for realistic rps.
    /// - Multiple withdrawal counts on the same stream at multiple points in time.
    function testFuzz_WithdrawMultiple_Usdc_SmallDelay(uint128 rps, uint256 withdrawCount, uint40 timeJump) external {
        rps = boundRatePerSecond(ud21x18(rps)).unwrap();

        IERC20 token = createToken(DECIMALS);
        uint256 streamId = createDefaultStream(ud21x18(rps), token);

        withdrawCount = _bound(withdrawCount, 10, 100);

        // Deposit the sufficient amount.
        uint128 sufficientDepositAmount = uint128(rps * 1 days * withdrawCount / SCALE_FACTOR);
        deposit(streamId, sufficientDepositAmount);

        // Actual total amount withdrawn in a given run.
        uint256 actualTotalWithdrawnAmount;

        uint40 timeBeforeFirstWithdraw = getBlockTimestamp();

        for (uint256 i; i < withdrawCount; ++i) {
            timeJump = boundUint40(timeJump, 1 hours, 1 days);

            // Warp the time.
            vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

            // Withdraw the tokens.
            (uint128 withdrawnAmount,) = flow.withdrawMax(streamId, users.recipient);
            actualTotalWithdrawnAmount += withdrawnAmount;
        }

        // Calculate the total stream period.
        uint40 totalStreamPeriod = getBlockTimestamp() - timeBeforeFirstWithdraw;

        // Calculate the desired amount.
        uint256 desiredTotalWithdrawnAmount = (rps * totalStreamPeriod) / SCALE_FACTOR;

        // Calculate the deviation.
        uint256 deviationAmount = desiredTotalWithdrawnAmount - actualTotalWithdrawnAmount;

        // Calculate the stream delay.
        uint256 streamDelay = (deviationAmount * SCALE_FACTOR) / rps;

        // Assert that the stream delay is within 5 second for the given fuzzed rps.
        assertLe(streamDelay, 5 seconds);

        // Assert that the deviation is less than 0.01e6 USDC.
        assertLe(deviationAmount, 0.01e6);

        // Assert that actual withdrawn amount is always less than the desired amount.
        assertLe(actualTotalWithdrawnAmount, desiredTotalWithdrawnAmount);
    }

    /// @dev Checklist:
    /// - It should test multiple withdrawals from the stream using `withdrawMax`.
    /// - It should assert that the actual withdrawn amount is always less than the desired amount.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple values for decimals
    /// - Multiple values for wide ranged rps.
    /// - Multiple withdrawal counts on the same stream at multiple points in time.
    function testFuzz_WithdrawMaxMultiple_RpsWideRange(
        uint128 rps,
        uint256 withdrawCount,
        uint40 timeJump,
        uint8 decimals
    )
        external
    {
        _test_WithdrawMultiple(rps, withdrawCount, timeJump, decimals, ISablierFlow.withdrawMax.selector, 0);
    }

    /// @dev Checklist:
    /// - It should test multiple withdrawals from the stream using `withdraw`.
    /// - It should assert that the actual withdrawn amount is always less than the desired amount.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple values for decimals
    /// - Multiple values for wide ranged rps.
    /// - Multiple amounts to withdraw.
    /// - Multiple withdrawal counts on the same stream at multiple points in time.
    function testFuzz_WithdrawMultiple_RpsWideRange(
        uint128 rps,
        uint128 withdrawAmount,
        uint256 withdrawCount,
        uint40 timeJump,
        uint8 decimals
    )
        external
    {
        _test_WithdrawMultiple(rps, withdrawCount, timeJump, decimals, ISablierFlow.withdraw.selector, withdrawAmount);
    }

    // Private helper function.
    function _test_WithdrawMultiple(
        uint128 rps,
        uint256 withdrawCount,
        uint40 timeJump,
        uint8 decimals,
        bytes4 selector,
        uint128 withdrawAmount
    )
        private
    {
        decimals = boundUint8(decimals, 0, 18);
        IERC20 token = createToken(decimals);

        // Bound rate per second to a wider range for 18 decimals.
        if (decimals == 18) {
            rps = boundUint128(rps, 0.0000000001e18, 2e18);
        }
        // For all other decimals, choose the minimum rps such that it takes 1 minute to stream 1 token.
        else {
            rps = boundUint128(rps, uint128(getScaledAmount(1, decimals)) / 60 + 1, 1e18);
        }

        uint256 streamId = createDefaultStream(ud21x18(rps), token);

        withdrawCount = _bound(withdrawCount, 100, 200);

        // Deposit the sufficient amount.
        uint256 sufficientDepositAmount = getDescaledAmount(uint128(rps * 1 days * withdrawCount), decimals);
        deposit(streamId, uint128(sufficientDepositAmount));

        // Actual total amount withdrawn in a given run.
        uint256 actualTotalWithdrawnAmount;

        uint40 timeBeforeFirstWithdraw = getBlockTimestamp();

        for (uint256 i; i < withdrawCount; ++i) {
            // Warp the time.
            timeJump = boundUint40(timeJump, 1 hours, 1 days);
            vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

            // Withdraw the tokens based on the selector value.
            // ISablierFlow.withdraw
            if (selector == ISablierFlow.withdraw.selector) {
                withdrawAmount = boundUint128(withdrawAmount, 1, flow.withdrawableAmountOf(streamId));
                flow.withdraw(streamId, users.recipient, withdrawAmount);
            }
            // ISablierFlow.withdrawMax
            else if (selector == ISablierFlow.withdrawMax.selector) {
                (withdrawAmount,) = flow.withdrawMax(streamId, users.recipient);
            }

            // Update the actual total amount withdrawn.
            actualTotalWithdrawnAmount += withdrawAmount;
        }

        uint40 totalStreamPeriod = getBlockTimestamp() - timeBeforeFirstWithdraw;
        uint256 desiredTotalWithdrawnAmount = getDescaledAmount(rps * totalStreamPeriod, decimals);

        // Assert that actual withdrawn amount is always less than the desired amount.
        assertLe(actualTotalWithdrawnAmount, desiredTotalWithdrawnAmount);
    }
}
