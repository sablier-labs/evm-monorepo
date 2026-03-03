// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

contract Getters_LidoAdapter_Integration_Concrete_Test is Integration_Test {
    function test_GetTotalYieldBearingTokenBalance() external view {
        // It should return the total wstETH balance.
        assertEq(
            adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter),
            WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            "totalYieldBearingTokenBalance"
        );
    }

    function test_GetVaultYieldFee() external view {
        // It should return the yield fee.
        assertEq(adapter.getVaultYieldFee(vaultIds.vaultWithAdapter), YIELD_FEE, "vaultYieldFee");
    }

    function test_GetWethReceivedAfterUnstaking() external {
        // Warp past expiry and unstake tokens.
        vm.warp(EXPIRY + 1);
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);

        // It should return the WETH received.
        assertEq(
            adapter.getWethReceivedAfterUnstaking(vaultIds.vaultWithAdapter), WETH_STAKED, "wethReceivedAfterUnstaking"
        );
    }

    function test_GetYieldBearingTokenBalanceFor() external {
        // Deposit into vault so that we have two users in the vault.
        setMsgSender(users.newDepositor);
        bob.enter(vaultIds.vaultWithAdapter, DEPOSIT_AMOUNT);

        assertEq(
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor),
            WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            "yieldBearingTokenBalance"
        );
    }
}
