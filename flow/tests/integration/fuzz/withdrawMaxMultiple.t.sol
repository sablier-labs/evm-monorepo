// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud21x18 } from "@prb/math/src/UD21x18.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract WithdrawMaxMultiple_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev Checklist:
    /// - It should test multiple withdrawals from the stream using `withdrawMax`.
    /// - It should assert that the actual withdrawn amount is equal to the desired amount.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed for USDC:
    /// - Multiple values for realistic rps.
    /// - Multiple withdrawal counts on the same stream at multiple points in time.
    function testFuzz_WithdrawMaxMultiple_Usdc(uint256 maxNumberOfWithdrawals, uint128 rps, uint40 timeJump) external {
        rps = boundRatePerSecond(ud21x18(rps)).unwrap();

        _test_WithdrawMaxMultiple(DECIMALS, maxNumberOfWithdrawals, rps, timeJump);
    }

    /// @dev Checklist:
    /// - It should test multiple withdrawals from the stream using `withdrawMax`.
    /// - It should assert that the actual withdrawn amount is equal to the desired amount.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple values for decimals
    /// - Multiple values for wide ranged rps but not extremely high.
    /// - Multiple withdrawal counts on the same stream at multiple points in time.
    function testFuzz_WithdrawMaxMultiple_RpsWideRange(
        uint8 decimals,
        uint256 maxNumberOfWithdrawals,
        uint128 rps,
        uint40 timeJump
    )
        external
    {
        decimals = boundUint8(decimals, 0, 18);

        // Bound rate per second to a wider range for 18 decimals.
        if (decimals == 18) {
            rps = boundUint128(rps, 0.0000000001e18, 2e18);
        }
        // For all other decimals, choose the minimum rps such that it takes 1 minute to stream 1 token.
        else {
            rps = boundUint128(rps, uint128(getScaledAmount(1, decimals)) / 60 + 1, 2e18);
        }

        _test_WithdrawMaxMultiple(decimals, maxNumberOfWithdrawals, rps, timeJump);
    }

    /// @dev Checklist:
    /// - It should test multiple withdrawals from the stream using `withdrawMax`.
    /// - It should assert that the actual withdrawn amount is equal to the desired amount.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple values for decimals
    /// - Multiple values for extremely large rps.
    /// - Multiple withdrawal counts on the same stream at multiple points in time.
    function testFuzz_WithdrawMaxMultiple_ExtremelyLargeRps(
        uint8 decimals,
        uint256 maxNumberOfWithdrawals,
        uint128 rps,
        uint40 timeJump
    )
        external
    {
        decimals = boundUint8(decimals, 0, 18);

        // Bound rate per second to extremely large values.
        rps = boundUint128(rps, 2e18, MAX_UINT128);

        _test_WithdrawMaxMultiple(decimals, maxNumberOfWithdrawals, rps, timeJump);
    }

    /// @dev Private shared function.
    function _test_WithdrawMaxMultiple(
        uint8 decimals,
        uint256 maxNumberOfWithdrawals,
        uint128 rps,
        uint40 timeJump
    )
        private
    {
        IERC20 token = createToken(decimals);
        uint256 streamId = createDefaultStream(ud21x18(rps), token);

        // Bound the maximum number of withdrawals to a reasonable range.
        maxNumberOfWithdrawals = _bound(maxNumberOfWithdrawals, 100, 200);

        // Deposit the maximum amount into the stream.
        deposit(streamId, MAX_UINT128);

        uint256 actualTotalWithdrawnAmount;
        uint256 numberOfWithdrawals;
        uint40 timeBeforeFirstWithdraw = getBlockTimestamp();

        // Run the loop until the maximum number of withdrawals is reached or the total withdrawn amount exceeds the
        // maximum uint128 value.
        while (numberOfWithdrawals++ < maxNumberOfWithdrawals && actualTotalWithdrawnAmount < MAX_UINT128) {
            // Skip forward the time.
            timeJump = boundUint40(timeJump, 1 hours, 1 days);
            skip(timeJump);

            uint128 withdrawAmount = flow.withdrawMax{ value: FLOW_MIN_FEE_WEI }(streamId, users.recipient);

            // Update the actual total amount withdrawn.
            actualTotalWithdrawnAmount += withdrawAmount;
        }

        // Calculate the total stream period.
        uint40 totalStreamPeriod = getBlockTimestamp() - timeBeforeFirstWithdraw;

        // Calculate the expected amount.
        uint256 expectedStreamedAmount = getDescaledAmount(uint256(rps) * totalStreamPeriod, decimals);
        uint256 expectedTotalWithdrawnAmount =
            expectedStreamedAmount > MAX_UINT128 ? MAX_UINT128 : expectedStreamedAmount;

        // Assert that actual sum of withdrawn amounts equal the expected amount.
        assertEq(actualTotalWithdrawnAmount, expectedTotalWithdrawnAmount);
    }
}
