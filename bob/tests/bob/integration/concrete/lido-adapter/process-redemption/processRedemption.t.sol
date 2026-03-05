// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract ProcessRedemption_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Deposit into vault so that we have two users in the vault.
        setMsgSender(users.newDepositor);
        bob.enter(vaultIds.vaultWithAdapter, DEPOSIT_AMOUNT);

        // Warp past expiry.
        vm.warp(EXPIRY + 1);
    }

    function test_RevertWhen_CallerNotBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.newDepositor, address(bob))
        );
        adapter.processRedemption(vaultIds.vaultWithAdapter, users.newDepositor, DEPOSIT_AMOUNT);
    }

    function test_GivenTotalWstETHZero() external whenCallerBob {
        // Assert that total wstETH is zero.
        assertEq(adapter.getTotalYieldBearingTokenBalance(vaultIds.defaultVault), 0, "totalYieldBearingTokenBalance");

        // It should return zero.
        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) =
            adapter.processRedemption(vaultIds.defaultVault, users.newDepositor, DEPOSIT_AMOUNT);

        assertEq(transferAmount, 0, "transferAmount");
        assertEq(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield");
    }

    function test_GivenTotalWETHZero() external whenCallerBob givenTotalWstETHNotZero {
        // Calculate the expected wstETH balance of the adapter as there are two users in the vault.
        uint256 expectedWstETHBalanceOfAdapter = 2 * WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT;

        // Assert that total WETH is zero but total wstETH is not zero.
        assertEq(adapter.getWethReceivedAfterUnstaking(vaultIds.vaultWithAdapter), 0, "wethReceivedAfterUnstaking");
        assertEq(
            adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter),
            expectedWstETHBalanceOfAdapter,
            "totalYieldBearingTokenBalance"
        );

        // It should return zero.
        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) =
            adapter.processRedemption(vaultIds.vaultWithAdapter, users.newDepositor, DEPOSIT_AMOUNT);

        assertEq(transferAmount, 0, "transferAmount");
        assertEq(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield");
    }

    function test_WhenUserWETHExceedsShareBalance()
        external
        whenCallerBob
        givenTotalWstETHNotZero
        givenTotalWETHNotZero
    {
        // Set a new exchange rate so both users have some yield.
        UD60x18 newExchangeRate = UD60x18.wrap(0.5e18);
        wstEth.setExchangeRate(newExchangeRate);
        // Unstake tokens in adapter.
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);

        // Calculate expected values.
        uint128 expectedAmountUnstakedForDepositor =
            expectedWethFromWstEth(WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT, newExchangeRate);
        (uint128 expectedFeeOnYield, uint128 expectedAmountToTransfer) =
            calculateYieldBreakdown(expectedAmountUnstakedForDepositor, DEPOSIT_AMOUNT, YIELD_FEE);

        // Store the vault total wstETH before processing.
        uint128 vaultTotalWstETHBefore = adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter);

        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) =
            adapter.processRedemption(vaultIds.vaultWithAdapter, users.depositor, DEPOSIT_AMOUNT);

        // It should return the correct fee amount.
        assertGt(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield > 0");
        assertEq(feeAmountDeductedFromYield, expectedFeeOnYield, "feeAmountDeductedFromYield");

        // It should return the correct amount to transfer to user.
        assertEq(transferAmount, expectedAmountToTransfer, "transferAmount");

        // It should clear the user wstETH balance.
        assertEq(
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor),
            0,
            "userWstETH after processing"
        );

        // It should not change the vault total wstETH.
        assertEq(
            adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter),
            vaultTotalWstETHBefore,
            "vaultTotalWstETH unchanged"
        );
    }

    function test_WhenUserWETHNotExceedShareBalance()
        external
        whenCallerBob
        givenTotalWstETHNotZero
        givenTotalWETHNotZero
    {
        // Unstake tokens in adapter.
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);

        // Store the vault total wstETH before processing.
        uint128 vaultTotalWstETHBefore = adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter);

        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) =
            adapter.processRedemption(vaultIds.vaultWithAdapter, users.depositor, DEPOSIT_AMOUNT);

        // It should return correct amount to transfer to user.
        assertEq(transferAmount, DEPOSIT_AMOUNT, "transferAmount");

        // It should return zero fee amount.
        assertEq(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield");

        // It should clear the user wstETH balance.
        assertEq(
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor),
            0,
            "userWstETH after processing"
        );

        // It should not change the vault total wstETH.
        assertEq(
            adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter),
            vaultTotalWstETHBefore,
            "vaultTotalWstETH unchanged"
        );
    }
}
