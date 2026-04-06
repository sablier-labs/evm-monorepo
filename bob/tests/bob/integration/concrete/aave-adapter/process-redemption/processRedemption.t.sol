// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract ProcessRedemption_AaveAdapter_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Deposit into vault so that we have two users in the vault.
        setMsgSender(users.newDepositor);
        bob.enter(vaultIds.vaultWithAaveAdapter, WBTC_DEPOSIT_AMOUNT);

        // Warp past expiry.
        vm.warp(EXPIRY + 1);
    }

    function test_RevertWhen_CallerNotBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierAaveAdapter_OnlySablierBob.selector, users.newDepositor, address(bob))
        );
        aaveAdapter.processRedemption(vaultIds.vaultWithAaveAdapter, users.newDepositor, WBTC_DEPOSIT_AMOUNT);
    }

    function test_GivenTotalScaledBalanceZero() external whenCallerBob {
        // Assert that total yield bearing token balance is zero for default vault (no adapter).
        assertEq(
            aaveAdapter.getTotalYieldBearingTokenBalance(vaultIds.defaultVault), 0, "totalYieldBearingTokenBalance"
        );

        // It should return zero.
        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) =
            aaveAdapter.processRedemption(vaultIds.defaultVault, users.newDepositor, DEPOSIT_AMOUNT);

        assertEq(transferAmount, 0, "transferAmount");
        assertEq(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield");
    }

    function test_GivenTotalTokensReceivedZero() external whenCallerBob givenTotalScaledBalanceNotZero {
        // Assert that total tokens received is zero but total scaled balance is not zero.
        assertEq(
            aaveAdapter.getTokensReceivedAfterUnstaking(vaultIds.vaultWithAaveAdapter),
            0,
            "tokensReceivedAfterUnstaking"
        );
        assertGt(
            aaveAdapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAaveAdapter),
            0,
            "totalYieldBearingTokenBalance"
        );

        // It should return zero.
        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) =
            aaveAdapter.processRedemption(vaultIds.vaultWithAaveAdapter, users.newDepositor, WBTC_DEPOSIT_AMOUNT);

        assertEq(transferAmount, 0, "transferAmount");
        assertEq(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield");
    }

    function test_WhenUserTokenShareExceedsShareBalance()
        external
        whenCallerBob
        givenTotalScaledBalanceNotZero
        givenTotalTokensReceivedNotZero
    {
        // Simulate yield by increasing normalized income by 20%.
        uint256 newNormalizedIncome = 1.2e27;
        aavePool.setNormalizedIncome(newNormalizedIncome);

        // Deal extra WBTC to the pool to cover accrued interest.
        uint256 totalATokenBalance = 2 * uint256(WBTC_DEPOSIT_AMOUNT) * newNormalizedIncome / 1e27;
        deal(address(wbtc), address(aavePool), totalATokenBalance);

        // Unstake tokens in adapter.
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAaveAdapter);

        // Calculate expected values.
        uint128 expectedAmountForDepositor =
            uint128(uint256(WBTC_DEPOSIT_AMOUNT) * totalATokenBalance / (2 * uint256(WBTC_DEPOSIT_AMOUNT)));
        (uint128 expectedFeeOnYield, uint128 expectedAmountToTransfer) =
            calculateYieldBreakdown(expectedAmountForDepositor, WBTC_DEPOSIT_AMOUNT, YIELD_FEE);

        // Store the vault total yield bearing token balance before processing.
        uint128 vaultTotalBefore = aaveAdapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAaveAdapter);

        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) =
            aaveAdapter.processRedemption(vaultIds.vaultWithAaveAdapter, users.depositor, WBTC_DEPOSIT_AMOUNT);

        // It should return the correct fee amount.
        assertGt(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield > 0");
        assertEq(feeAmountDeductedFromYield, expectedFeeOnYield, "feeAmountDeductedFromYield");

        // It should return the correct amount to transfer to user.
        assertEq(transferAmount, expectedAmountToTransfer, "transferAmount");

        // It should clear the user scaled balance.
        assertEq(
            aaveAdapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAaveAdapter, users.depositor),
            0,
            "userScaledBalance after processing"
        );

        // It should not change the vault total scaled balance.
        assertEq(
            aaveAdapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAaveAdapter),
            vaultTotalBefore,
            "vaultTotalScaledBalance unchanged"
        );
    }

    function test_WhenUserTokenShareNotExceedShareBalance()
        external
        whenCallerBob
        givenTotalScaledBalanceNotZero
        givenTotalTokensReceivedNotZero
    {
        // Unstake tokens in adapter (no yield change).
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAaveAdapter);

        // Store the vault total before processing.
        uint128 vaultTotalBefore = aaveAdapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAaveAdapter);

        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) =
            aaveAdapter.processRedemption(vaultIds.vaultWithAaveAdapter, users.depositor, WBTC_DEPOSIT_AMOUNT);

        // It should return correct amount to transfer to user.
        assertEq(transferAmount, WBTC_DEPOSIT_AMOUNT, "transferAmount");

        // It should return zero fee amount.
        assertEq(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield");

        // It should clear the user scaled balance.
        assertEq(
            aaveAdapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAaveAdapter, users.depositor),
            0,
            "userScaledBalance after processing"
        );

        // It should not change the vault total scaled balance.
        assertEq(
            aaveAdapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAaveAdapter),
            vaultTotalBefore,
            "vaultTotalScaledBalance unchanged"
        );
    }
}
