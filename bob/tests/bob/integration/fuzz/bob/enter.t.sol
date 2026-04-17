// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud } from "@prb/math/src/UD60x18.sol";

import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Enter_Integration_Fuzz_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Change caller to new depositor for this test.
        setMsgSender(users.newDepositor);
    }

    function testFuzz_Enter_GivenNoAdapter(uint128 amount)
        external
        givenNotNull
        givenACTIVEStatus
        whenAmountNotZero
        whenSyncNotChangeStatus
    {
        amount = boundUint128(amount, 1, MAX_UINT128);

        // Create a DAI vault.
        uint256 daiVaultId = bob.createVault({ token: dai, oracle: oracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });
        IBobVaultShare daiShareToken = bob.getShareToken(daiVaultId);

        // Deal DAI to new depositor and approve.
        deal({ token: address(dai), to: users.newDepositor, give: amount });
        dai.approve(address(bob), amount);

        uint256 shareBalanceBefore = daiShareToken.balanceOf(users.newDepositor);

        // It should emit an {Enter} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Enter({
            vaultId: daiVaultId,
            user: users.newDepositor,
            amountReceived: amount,
            sharesMinted: amount
        });

        // It should transfer tokens to the contract.
        expectCallToTransferFrom({ token: dai, from: users.newDepositor, to: address(bob), value: amount });

        bob.enter(daiVaultId, amount);

        // It should mint share tokens 1:1 with the deposit amount.
        uint256 actualSharesMinted = daiShareToken.balanceOf(users.newDepositor) - shareBalanceBefore;
        assertEq(actualSharesMinted, amount, "sharesMinted");
    }

    function testFuzz_Enter(uint128 amount)
        external
        givenAdapter
        givenNotNull
        givenACTIVEStatus
        whenAmountNotZero
        whenSyncNotChangeStatus
    {
        amount = boundUint128(amount, 1, LIDO_MAX_STETH_WITHDRAWAL_AMOUNT);

        // Deal WETH to new depositor and approve.
        deal({ token: address(weth), to: users.newDepositor, give: amount });
        weth.approve(address(bob), amount);

        IBobVaultShare shareTokenForVaultWithAdapter = bob.getShareToken(vaultIds.vaultWithAdapter);
        uint256 shareBalanceBefore = shareTokenForVaultWithAdapter.balanceOf(users.newDepositor);

        uint128 expectedWstETH = ud(amount).mul(WSTETH_WETH_EXCHANGE_RATE).intoUint128();

        // It should emit {Stake} and {Enter} events.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.Stake({
            vaultId: vaultIds.vaultWithAdapter,
            user: users.newDepositor,
            depositAmount: amount,
            wrappedStakedAmount: expectedWstETH
        });

        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Enter({
            vaultId: vaultIds.vaultWithAdapter,
            user: users.newDepositor,
            amountReceived: amount,
            sharesMinted: amount
        });

        // It should transfer tokens to the adapter.
        expectCallToTransferFrom({ token: weth, from: users.newDepositor, to: address(adapter), value: amount });

        bob.enter(vaultIds.vaultWithAdapter, amount);

        // It should mint share tokens 1:1 with the deposit amount.
        uint256 actualSharesMinted = shareTokenForVaultWithAdapter.balanceOf(users.newDepositor) - shareBalanceBefore;
        assertEq(actualSharesMinted, amount, "sharesMinted");

        // It should stake via the adapter and track wstETH.
        uint256 actualWstETH = adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.newDepositor);
        assertEq(actualWstETH, expectedWstETH, "userWstETH");
    }
}
