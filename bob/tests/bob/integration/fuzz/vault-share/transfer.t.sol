// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Transfer_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_Transfer_GivenNoAdapter(uint128 transferAmount) external {
        transferAmount = boundUint128(transferAmount, 1, DEPOSIT_AMOUNT);

        uint256 senderBalanceBefore = defaultShareToken.balanceOf(users.depositor);
        uint256 recipientBalanceBefore = defaultShareToken.balanceOf(users.newDepositor);

        // It should call onShareTransfer on Bob.
        vm.expectCall(address(bob), abi.encodeWithSelector(ISablierBob.onShareTransfer.selector), 1);

        // It should not call updateStakedTokenBalance on adapter.
        vm.expectCall(address(adapter), abi.encodeWithSelector(ISablierBobAdapter.updateStakedTokenBalance.selector), 0);

        defaultShareToken.transfer(users.newDepositor, transferAmount);

        // It should decrease sender's balance.
        uint256 actualSenderBalance = defaultShareToken.balanceOf(users.depositor);
        uint256 expectedSenderBalance = senderBalanceBefore - transferAmount;
        assertEq(actualSenderBalance, expectedSenderBalance, "sender balance");

        // It should increase recipient's balance.
        uint256 actualRecipientBalance = defaultShareToken.balanceOf(users.newDepositor);
        uint256 expectedRecipientBalance = recipientBalanceBefore + transferAmount;
        assertEq(actualRecipientBalance, expectedRecipientBalance, "recipient balance");
    }

    function testFuzz_Transfer(uint128 transferAmount) external givenAdapter {
        transferAmount = boundUint128(transferAmount, 2, DEPOSIT_AMOUNT);

        IBobVaultShare shareTokenForVaultWithAdapter = bob.getShareToken(vaultIds.vaultWithAdapter);

        uint256 senderBalanceBefore = shareTokenForVaultWithAdapter.balanceOf(users.depositor);
        uint256 recipientBalanceBefore = shareTokenForVaultWithAdapter.balanceOf(users.newDepositor);

        uint128 senderWstETHBefore = adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor);
        uint128 vaultTotalWstETHBefore = adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter);

        // It should call onShareTransfer on Bob.
        vm.expectCall(address(bob), abi.encodeWithSelector(ISablierBob.onShareTransfer.selector), 1);

        // It should call updateStakedTokenBalance on adapter.
        vm.expectCall(address(adapter), abi.encodeWithSelector(ISablierBobAdapter.updateStakedTokenBalance.selector), 1);

        shareTokenForVaultWithAdapter.transfer(users.newDepositor, transferAmount);

        // It should decrease sender's balance.
        uint256 actualSenderBalance = shareTokenForVaultWithAdapter.balanceOf(users.depositor);
        uint256 expectedSenderBalance = senderBalanceBefore - transferAmount;
        assertEq(actualSenderBalance, expectedSenderBalance, "sender balance");

        // It should increase recipient's balance.
        uint256 actualRecipientBalance = shareTokenForVaultWithAdapter.balanceOf(users.newDepositor);
        uint256 expectedRecipientBalance = recipientBalanceBefore + transferAmount;
        assertEq(actualRecipientBalance, expectedRecipientBalance, "recipient balance");

        // It should proportionally move wstETH from sender to recipient.
        uint128 expectedWstETHTransfer = uint128(uint256(senderWstETHBefore) * transferAmount / senderBalanceBefore);
        uint128 actualSenderWstETH = adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor);
        uint128 actualRecipientWstETH =
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.newDepositor);

        assertEq(actualSenderWstETH, senderWstETHBefore - expectedWstETHTransfer, "sender wstETH");
        assertEq(actualRecipientWstETH, expectedWstETHTransfer, "recipient wstETH");

        // It should not change the vault total wstETH.
        assertEq(
            adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter),
            vaultTotalWstETHBefore,
            "vault total wstETH"
        );
    }
}
