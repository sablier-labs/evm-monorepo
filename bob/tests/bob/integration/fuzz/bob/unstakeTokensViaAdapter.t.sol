// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract UnstakeTokensViaAdapter_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_UnstakeTokensViaAdapter(uint256 exchangeRateRaw)
        external
        givenNotNull
        givenAdapter
        givenNotAlreadyUnstaked
        givenYieldTokenBalanceNotZero
        givenNotACTIVEStatus
    {
        exchangeRateRaw = bound(exchangeRateRaw, 0.1e18, 0.89e18);
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

        // It should emit an {UnstakeFromAdapter} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.UnstakeFromAdapter(
            vaultIds.vaultWithAdapter,
            adapter,
            WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            expectedWethRedeemed
        );

        // It should transfer tokens back to Bob.
        expectCallToTransfer(weth, address(bob), expectedWethRedeemed);

        uint128 amountReceived = bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);

        // It should return the correct amount.
        assertEq(amountReceived, expectedWethRedeemed, "returnValue.amountReceived");

        // It should mark the vault as unstaked.
        assertFalse(bob.isStakedInAdapter(vaultIds.vaultWithAdapter), "isStakedInAdapter");

        // It should store the WETH received for redemption calculations.
        assertEq(
            adapter.getWethReceivedAfterUnstaking(vaultIds.vaultWithAdapter),
            expectedWethRedeemed,
            "wethReceivedAfterUnstaking"
        );
    }
}
