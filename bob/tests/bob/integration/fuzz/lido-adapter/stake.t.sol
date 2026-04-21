// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud } from "@prb/math/src/UD60x18.sol";

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Stake_Integration_Fuzz_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Transfer WETH to the adapter before calling `stake`, since this test calls the adapter directly.
        weth.transfer(address(adapter), LIDO_MAX_STETH_WITHDRAWAL_AMOUNT);
    }

    function testFuzz_Stake(uint128 amount) external whenCallerBob {
        amount = boundUint128(amount, 1, LIDO_MAX_STETH_WITHDRAWAL_AMOUNT);

        uint128 userWstETHBefore = adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.newDepositor);
        uint128 vaultTotalWstETHBefore = adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter);

        uint128 expectedWstETH = ud(amount).mul(WSTETH_WETH_EXCHANGE_RATE).intoUint128();

        // It should emit a {Stake} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.Stake({
            vaultId: vaultIds.vaultWithAdapter,
            user: users.newDepositor,
            depositAmount: amount,
            wrappedStakedAmount: expectedWstETH
        });

        adapter.stake(vaultIds.vaultWithAdapter, users.newDepositor, amount);

        // It should update the user's wstETH balance.
        uint128 actualUserWstETH = adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.newDepositor);
        assertEq(actualUserWstETH, userWstETHBefore + expectedWstETH, "userWstETH");

        // It should update the vault total wstETH balance.
        uint128 actualVaultTotalWstETH = adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter);
        assertEq(actualVaultTotalWstETH, vaultTotalWstETHBefore + expectedWstETH, "vaultTotalWstETH");
    }
}
