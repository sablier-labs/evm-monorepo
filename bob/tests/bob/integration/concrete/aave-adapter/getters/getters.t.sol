// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

contract Getters_AaveAdapter_Integration_Concrete_Test is Integration_Test {
    function test_GetTokensReceivedAfterUnstaking_WhenNotUnstaked() external view {
        assertEq(
            aaveAdapter.getTokensReceivedAfterUnstaking(vaultIds.vaultWithAaveAdapter),
            0,
            "tokensReceivedAfterUnstaking before unstake"
        );
    }

    function test_GetTokensReceivedAfterUnstaking_WhenUnstaked() external {
        // Warp past expiry and unstake tokens.
        vm.warp(EXPIRY + 1);
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAaveAdapter);

        // It should return the tokens received.
        assertEq(
            aaveAdapter.getTokensReceivedAfterUnstaking(vaultIds.vaultWithAaveAdapter),
            WBTC_DEPOSIT_AMOUNT,
            "tokensReceivedAfterUnstaking after unstake"
        );
    }

    function test_GetTotalYieldBearingTokenBalance() external view {
        // It should return the total aToken balance.
        assertEq(
            aaveAdapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAaveAdapter),
            WBTC_DEPOSIT_AMOUNT,
            "totalYieldBearingTokenBalance"
        );
    }

    function test_GetAaveTokenBalanceScaled() external view {
        // It should return the total scaled balance.
        assertEq(
            aaveAdapter.getAaveTokenBalanceScaled(vaultIds.vaultWithAaveAdapter),
            WBTC_DEPOSIT_AMOUNT,
            "aTokenTotalScaledBalance"
        );
    }

    function test_GetAaveTokenBalanceScaledFor() external view {
        // It should return the user's scaled balance.
        assertEq(
            aaveAdapter.getAaveTokenBalanceScaledFor(vaultIds.vaultWithAaveAdapter, users.depositor),
            WBTC_DEPOSIT_AMOUNT,
            "aTokenUserScaledBalance"
        );
    }

    function test_GetVaultYieldFee() external view {
        // It should return the yield fee.
        assertEq(aaveAdapter.getVaultYieldFee(vaultIds.vaultWithAaveAdapter), YIELD_FEE, "vaultYieldFee");
    }

    function test_GetYieldBearingTokenBalanceFor() external view {
        // It should return the user's aToken balance.
        assertEq(
            aaveAdapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAaveAdapter, users.depositor),
            WBTC_DEPOSIT_AMOUNT,
            "yieldBearingTokenBalance"
        );
    }
}
