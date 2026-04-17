// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract ProcessRedemption_Integration_Fuzz_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Add a second depositor into the adapter vault.
        setMsgSender(users.newDepositor);
        vm.deal(users.newDepositor, 10_000 ether);
        weth.deposit{ value: 10_000 ether }();
        weth.approve(address(bob), MAX_UINT128);
        bob.enter(vaultIds.vaultWithAdapter, DEPOSIT_AMOUNT);

        // Restore the default caller.
        setMsgSender(users.depositor);

        // Warp past expiry so the vault is expired.
        vm.warp(EXPIRY + 1);
    }

    function testFuzz_ProcessRedemption_GivenNegativeYield(uint256 exchangeRateRaw)
        external
        whenCallerBob
        givenTotalWstETHNotZero
        givenTotalWETHNotZero
    {
        exchangeRateRaw = bound(exchangeRateRaw, WSTETH_WETH_EXCHANGE_RATE.unwrap(), 2e18);
        UD60x18 newExchangeRate = UD60x18.wrap(exchangeRateRaw);

        wstEth.setExchangeRate(newExchangeRate);

        // Unstake tokens from the adapter so that WETH is available for redemption.
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);

        uint128 expectedWethRedeemed = expectedWethFromWstEth(WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT, newExchangeRate);

        uint128 vaultTotalWstETHBefore = adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter);

        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) =
            adapter.processRedemption(vaultIds.vaultWithAdapter, users.depositor, DEPOSIT_AMOUNT);

        // It should return the WETH share with no fee.
        assertEq(transferAmount, expectedWethRedeemed, "transferAmount");
        assertLe(transferAmount, DEPOSIT_AMOUNT, "transferAmount <= depositAmount");
        assertEq(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield");

        // It should clear the user's wstETH balance.
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

    function testFuzz_ProcessRedemption(uint256 exchangeRateRaw)
        external
        whenCallerBob
        givenTotalWstETHNotZero
        givenTotalWETHNotZero
    {
        exchangeRateRaw = bound(exchangeRateRaw, 0.1e18, 0.89e18);
        UD60x18 newExchangeRate = UD60x18.wrap(exchangeRateRaw);

        wstEth.setExchangeRate(newExchangeRate);

        // Unstake tokens from the adapter so that WETH is available for redemption.
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);

        uint128 expectedWethRedeemed = expectedWethFromWstEth(WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT, newExchangeRate);
        (uint128 expectedFee, uint128 expectedNet) =
            calculateYieldBreakdown(expectedWethRedeemed, DEPOSIT_AMOUNT, YIELD_FEE);

        uint128 vaultTotalWstETHBefore = adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter);

        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) =
            adapter.processRedemption(vaultIds.vaultWithAdapter, users.depositor, DEPOSIT_AMOUNT);

        // It should return the correct transfer amount.
        assertEq(transferAmount, expectedNet, "transferAmount");

        // It should return the correct fee amount deducted from yield.
        assertGt(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield > 0");
        assertEq(feeAmountDeductedFromYield, expectedFee, "feeAmountDeductedFromYield");

        // It should clear the user's wstETH balance.
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
