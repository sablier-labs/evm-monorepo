// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract UnstakeFullAmount_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_UnstakeFullAmount(uint256 exchangeRateRaw) external whenCallerBob {
        exchangeRateRaw = bound(exchangeRateRaw, 0.1e18, 2e18);
        UD60x18 newExchangeRate = UD60x18.wrap(exchangeRateRaw);

        wstEth.setExchangeRate(newExchangeRate);

        uint128 expectedWethRedeemed = expectedWethFromWstEth(WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT, newExchangeRate);

        // It should emit an {UnstakeFullAmount} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.UnstakeFullAmount({
            vaultId: vaultIds.vaultWithAdapter,
            totalStakedAmount: WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            amountReceivedFromUnstaking: expectedWethRedeemed
        });

        // It should transfer WETH to Bob.
        expectCallToTransfer(weth, address(bob), expectedWethRedeemed);

        (uint128 wrappedTokenBalance, uint128 amountReceivedFromUnstaking) =
            adapter.unstakeFullAmount(vaultIds.vaultWithAdapter);

        // It should return the total wstETH that was in the vault.
        assertEq(wrappedTokenBalance, WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT, "wrappedTokenBalance");

        // It should return the WETH amount received from unstaking.
        assertEq(amountReceivedFromUnstaking, expectedWethRedeemed, "amountReceivedFromUnstaking");

        // It should store the WETH received for redemption calculations.
        assertEq(
            adapter.getWethReceivedAfterUnstaking(vaultIds.vaultWithAdapter),
            expectedWethRedeemed,
            "wethReceivedAfterUnstaking"
        );
    }
}
