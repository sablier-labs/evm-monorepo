// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract UpdateStakedTokenBalance_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_UpdateStakedTokenBalance(uint128 transferAmount) external whenCallerBob {
        transferAmount = boundUint128(transferAmount, 2, DEPOSIT_AMOUNT);

        uint128 senderWstETHBefore = adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor);
        uint128 recipientWstETHBefore =
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.newDepositor);
        uint128 vaultTotalWstETHBefore = adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter);

        // Calculate the expected proportional wstETH transfer.
        uint128 expectedWstETHTransfer = uint128(uint256(senderWstETHBefore) * transferAmount / DEPOSIT_AMOUNT);

        // It should emit a {TransferStakedTokens} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.TransferStakedTokens({
            vaultId: vaultIds.vaultWithAdapter,
            from: users.depositor,
            to: users.newDepositor,
            amount: expectedWstETHTransfer
        });

        adapter.updateStakedTokenBalance({
            vaultId: vaultIds.vaultWithAdapter,
            from: users.depositor,
            to: users.newDepositor,
            shareAmountTransferred: transferAmount,
            userShareBalanceBeforeTransfer: DEPOSIT_AMOUNT
        });

        // It should move wstETH from sender to recipient.
        uint128 actualSenderWstETH = adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor);
        uint128 actualRecipientWstETH =
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.newDepositor);

        assertEq(actualSenderWstETH, senderWstETHBefore - expectedWstETHTransfer, "sender wstETH");
        assertEq(actualRecipientWstETH, recipientWstETHBefore + expectedWstETHTransfer, "recipient wstETH");

        // It should not change the vault total wstETH.
        assertEq(
            adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter),
            vaultTotalWstETHBefore,
            "vault total wstETH"
        );
    }
}
