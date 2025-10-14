// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract CalculateClaimAmount_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_WhenClaimTimeZero() external {
        vm.warp({ newTimestamp: VCA_START_TIME - 1 seconds });
        uint40 claimTime = 0;

        // It should use block time and return zero.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, claimTime), 0, "calculateClaimAmount");
    }

    function test_WhenClaimTimeLessThanVestingStartTime() external view whenClaimTimeNotZero {
        uint40 claimTime = VCA_START_TIME - 1 seconds;

        // It should return zero.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, claimTime), 0, "calculateClaimAmount");
    }

    function test_WhenClaimTimeEqualVestingStartTime() external view whenClaimTimeNotZero {
        // It should return unlock amount.
        assertEq(
            merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, VCA_START_TIME), VCA_UNLOCK_AMOUNT, "calculateClaimAmount"
        );
    }

    function test_WhenClaimTimeNotLessThanVestingEndTime()
        external
        view
        whenClaimTimeNotZero
        whenClaimTimeGreaterThanVestingStartTime
    {
        // It should return the full amount.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, VCA_END_TIME), VCA_FULL_AMOUNT, "calculateClaimAmount");
    }

    function test_WhenClaimTimeLessThanVestingEndTime()
        external
        view
        whenClaimTimeNotZero
        whenClaimTimeGreaterThanVestingStartTime
    {
        // It should return the vested amount.
        assertEq(
            merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, getBlockTimestamp()),
            VCA_CLAIM_AMOUNT,
            "calculateClaimAmount"
        );
    }
}
