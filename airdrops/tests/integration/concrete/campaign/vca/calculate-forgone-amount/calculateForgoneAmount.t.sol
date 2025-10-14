// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract CalculateForgoneAmount_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_WhenClaimTimeZero() external view {
        uint40 claimTime = 0;
        uint128 expectedForgoneAmount = VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT;

        // It should use block time.
        assertEq(merkleVCA.calculateForgoneAmount(VCA_FULL_AMOUNT, claimTime), expectedForgoneAmount, "forgone amount");
    }

    function test_RevertWhen_ClaimTimeLessThanVestingStartTime() external whenClaimTimeNotZero {
        uint40 claimTime = VCA_START_TIME - 1 seconds;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleVCA_VestingNotStarted.selector, claimTime, VCA_START_TIME)
        );

        // It should revert.
        merkleVCA.calculateForgoneAmount(VCA_FULL_AMOUNT, claimTime);
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
