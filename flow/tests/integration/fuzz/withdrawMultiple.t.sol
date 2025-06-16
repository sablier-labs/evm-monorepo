// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud21x18 } from "@prb/math/src/UD21x18.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract WithdrawMaxMultiple_NoDelay_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev Checklist:
    /// - It should test multiple withdrawals from the stream using `withdrawMax`.
    /// - It should assert that the actual withdrawn amount is equal to the desired amount.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed for USDC:
    /// - Multiple values for realistic rps.
    /// - Multiple withdrawal counts on the same stream at multiple points in time.
    function testFuzz_WithdrawMaxMultiple_Usdc_NoDelay(uint128 rps, uint256 withdrawCount, uint40 timeJump) external {
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

            // Skip forward by `timeJump`.
            skip(timeJump);

            // Withdraw the tokens.
            uint128 withdrawnAmount = flow.withdrawMax{ value: FLOW_MIN_FEE_WEI }(streamId, users.recipient);
            actualTotalWithdrawnAmount += withdrawnAmount;
        }

        // Calculate the total stream period.
        uint40 totalStreamPeriod = getBlockTimestamp() - timeBeforeFirstWithdraw;

        // Calculate the desired amount.
        uint256 desiredTotalWithdrawnAmount = (rps * totalStreamPeriod) / SCALE_FACTOR;

        // Assert that actual sum of withdrawn amount equals the total desired amount.
        assertEq(actualTotalWithdrawnAmount, desiredTotalWithdrawnAmount);
    }

    /// @dev Checklist:
    /// - It should test multiple withdrawals from the stream using `withdrawMax`.
    /// - It should assert that the actual withdrawn amount is equal to the desired amount.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple values for decimals
    /// - Multiple values for wide ranged rps.
    /// - Multiple withdrawal counts on the same stream at multiple points in time.
    function testFuzz_WithdrawMaxMultiple_RpsWideRange_NoDelay(
        uint128 rps,
        uint256 withdrawCount,
        uint40 timeJump,
        uint8 decimals
    )
        external
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
            // Skip forward the time.
            timeJump = boundUint40(timeJump, 1 hours, 1 days);
            skip(timeJump);

            uint128 withdrawAmount = flow.withdrawMax{ value: FLOW_MIN_FEE_WEI }(streamId, users.recipient);

            // Update the actual total amount withdrawn.
            actualTotalWithdrawnAmount += withdrawAmount;
        }

        uint40 totalStreamPeriod = getBlockTimestamp() - timeBeforeFirstWithdraw;
        uint256 desiredTotalWithdrawnAmount = getDescaledAmount(rps * totalStreamPeriod, decimals);

        // Assert that actual sum of withdrawn amounts equal the desired amount.
        assertEq(actualTotalWithdrawnAmount, desiredTotalWithdrawnAmount);
    }
}
