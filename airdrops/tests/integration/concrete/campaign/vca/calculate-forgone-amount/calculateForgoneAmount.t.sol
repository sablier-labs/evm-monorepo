// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract CalculateForgoneAmount_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_WhenClaimTimeZero() external {
        vm.warp({ newTimestamp: VCA_START_TIME - 1 seconds });
        uint40 claimTime = 0;

        // It should use block time and return 0.
        assertEq(merkleVCA.calculateForgoneAmount(VCA_FULL_AMOUNT, claimTime), 0, "forgone amount");
    }

    function test_WhenClaimTimeLessThanVestingStartTime() external view whenClaimTimeNotZero {
        uint40 claimTime = VCA_START_TIME - 1 seconds;

        // It should return the full amount.
        assertEq(merkleVCA.calculateForgoneAmount(VCA_FULL_AMOUNT, claimTime), 0, "forgone amount");
    }

    function test_WhenClaimTimeEqualVestingStartTime() external view whenClaimTimeNotZero {
        // It should return full vesting amount.
        assertEq(
            merkleVCA.calculateForgoneAmount(VCA_FULL_AMOUNT, VCA_START_TIME), VCA_VESTING_AMOUNT, "forgone amount"
        );
    }

    function test_WhenClaimTimeNotLessThanVestingEndTime()
        external
        view
        whenClaimTimeNotZero
        whenClaimTimeGreaterThanVestingStartTime
    {
        // It should return 0.
        assertEq(merkleVCA.calculateForgoneAmount(VCA_FULL_AMOUNT, VCA_END_TIME), 0, "forgone amount");
    }

    function test_WhenClaimTimeLessThanVestingEndTime()
        external
        view
        whenClaimTimeNotZero
        whenClaimTimeGreaterThanVestingStartTime
    {
        uint128 expectedForgoneAmount = VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT;

        // It should return the correct amount.
        assertEq(
            merkleVCA.calculateForgoneAmount(VCA_FULL_AMOUNT, getBlockTimestamp()),
            expectedForgoneAmount,
            "forgone amount"
        );
    }
}
