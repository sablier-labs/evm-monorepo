// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud } from "@prb/math/src/UD60x18.sol";
import { Integration_Test } from "../../../Integration.t.sol";

contract CalculateAmountToTransferWithYield_Integration_Concrete_Test is Integration_Test {
    function test_GivenTotalWstETHZero() external view {
        // Assert that total wstETH is zero.
        assertEq(adapter.getTotalYieldBearingTokenBalance(vaultIds.defaultVault), 0, "totalYieldBearingTokenBalance");

        // It should return zero.
        (uint128 amountToTransfer, uint128 feeAmount) =
            adapter.calculateAmountToTransferWithYield(vaultIds.defaultVault, users.depositor, DEPOSIT_AMOUNT);

        assertEq(amountToTransfer, 0, "amountToTransfer");
        assertEq(feeAmount, 0, "feeAmount");
    }

    function test_GivenTotalWETHZero() external view givenTotalWstETHNotZero {
        // Assert that total WETH is zero but total wstETH is not zero.
        assertEq(adapter.getWethReceivedAfterUnstaking(vaultIds.vaultWithAdapter), 0, "wethReceivedAfterUnstaking");
        assertEq(
            adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter),
            WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            "totalYieldBearingTokenBalance"
        );

        // It should return zero.
        (uint128 amountToTransfer, uint128 feeAmount) =
            adapter.calculateAmountToTransferWithYield(vaultIds.vaultWithAdapter, users.depositor, DEPOSIT_AMOUNT);

        assertEq(amountToTransfer, 0, "amountToTransfer");
        assertEq(feeAmount, 0, "feeAmount");
    }

    function test_WhenUserWETHExceedsShareBalance() external givenTotalWstETHNotZero givenTotalWETHNotZero {
        // Set a lower exchange rate to simulate positive yield.
        wstEth.setExchangeRate(0.8e18);

        // Deposit into vault so that we have two users in the vault.
        setMsgSender(users.newDepositor);
        bob.enter(vaultIds.vaultWithAdapter, DEPOSIT_AMOUNT);

        // Set a new exchange rate so both users have some yield.
        wstEth.setExchangeRate(0.5e18);

        // Warp past expiry.
        vm.warp(EXPIRY + 1);

        // Unstake tokens in adapter.
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);

        // Calculate expected values.
        uint128 expectedAmountUnstakedForDepositor =
            ud(WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT).div(ud(0.5e18)).intoUint128();
        uint128 expectedYieldForDepositor = expectedAmountUnstakedForDepositor - DEPOSIT_AMOUNT;
        uint128 expectedFeeOnYield = ud(expectedYieldForDepositor).mul(YIELD_FEE).intoUint128();
        uint128 expectedAmountToTransfer = expectedAmountUnstakedForDepositor - expectedFeeOnYield;

        (uint128 amountToTransfer, uint128 feeAmount) =
            adapter.calculateAmountToTransferWithYield(vaultIds.vaultWithAdapter, users.depositor, DEPOSIT_AMOUNT);

        // It should return the correct fee amount.
        assertEq(feeAmount, expectedFeeOnYield, "feeAmount");

        // It should return the correct amount to transfer to user.
        assertEq(amountToTransfer, expectedAmountToTransfer, "amountToTransfer");
    }

    function test_WhenUserWETHNotExceedShareBalance() external givenTotalWstETHNotZero givenTotalWETHNotZero {
        // Deposit into vault so that we have two users in the vault.
        setMsgSender(users.newDepositor);
        bob.enter(vaultIds.vaultWithAdapter, DEPOSIT_AMOUNT);

        // Warp past expiry.
        vm.warp(EXPIRY + 1);

        // Unstake tokens in adapter.
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);

        (uint128 amountToTransfer, uint128 feeAmount) =
            adapter.calculateAmountToTransferWithYield(vaultIds.vaultWithAdapter, users.depositor, DEPOSIT_AMOUNT);

        // It should return correct amount to transfer to user.
        assertEq(amountToTransfer, DEPOSIT_AMOUNT, "amountToTransfer");

        // It should return zero fee amount.
        assertEq(feeAmount, 0, "feeAmount");
    }
}
