// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";

import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract OnShareTransfer_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotVaultShareToken() external {
        // Change caller to the share token of vault with adapter.
        address invalidShareToken = address(bob.getShareToken(vaultIds.vaultWithAdapter));
        setMsgSender(invalidShareToken);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierBob_CallerNotShareToken.selector, vaultIds.defaultVault, invalidShareToken
            )
        );
        bob.onShareTransfer(vaultIds.defaultVault, users.depositor, users.bob, DEPOSIT_AMOUNT, DEPOSIT_AMOUNT);
    }

    function test_GivenNoAdapter() external whenCallerVaultShareToken {
        address shareToken = address(bob.getShareToken(vaultIds.defaultVault));
        setMsgSender(shareToken);

        vm.recordLogs();

        bob.onShareTransfer(vaultIds.defaultVault, users.depositor, users.bob, DEPOSIT_AMOUNT, DEPOSIT_AMOUNT);

        // It should do nothing.
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0, "did something");
    }

    function test_RevertGiven_SenderBalanceZero() external whenCallerVaultShareToken givenAdapter {
        IBobVaultShare shareToken = bob.getShareToken(vaultIds.vaultWithAdapter);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_UserBalanceZero.selector, vaultIds.vaultWithAdapter, users.depositor
            )
        );

        setMsgSender(address(shareToken));
        bob.onShareTransfer(vaultIds.vaultWithAdapter, users.depositor, users.bob, DEPOSIT_AMOUNT, 0);
    }

    function test_GivenSenderBalanceNotZero() external whenCallerVaultShareToken givenAdapter {
        IBobVaultShare shareToken = bob.getShareToken(vaultIds.vaultWithAdapter);
        uint256 transferAmount = 1e18;

        uint256 expectedWstETHTransferred = WSTETH_WETH_EXCHANGE_RATE * transferAmount / 1e18;

        // It should emit a {TransferStakedTokens} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.TransferStakedTokens(
            vaultIds.vaultWithAdapter,
            users.depositor,
            users.bob,
            expectedWstETHTransferred
        );

        // Call transfer on vault share which will call `onShareTransfer` on Bob.
        setMsgSender(users.depositor);
        shareToken.transfer(users.bob, transferAmount);

        // It should decrease the sender share token balance.
        uint256 actualSenderBalance = shareToken.balanceOf(users.depositor);
        uint256 expectedSenderBalance = DEPOSIT_AMOUNT - transferAmount;
        assertEq(actualSenderBalance, expectedSenderBalance, "sender share token balance");

        // It should decrease the sender wstETH balance in adapter.
        uint256 actualSenderWstETHBalance =
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor);
        uint256 expectedSenderWstETHBalance = WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT - expectedWstETHTransferred;
        assertEq(actualSenderWstETHBalance, expectedSenderWstETHBalance, "sender wstETH balance in adapter");

        // It should increase the recipient share token balance.
        uint256 actualRecipientBalance = shareToken.balanceOf(users.bob);
        uint256 expectedRecipientBalance = transferAmount;
        assertEq(actualRecipientBalance, expectedRecipientBalance, "recipient share token balance");

        // It should increase the recipient wstETH balance in adapter.
        uint256 actualRecipientWstETHBalance =
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.bob);
        uint256 expectedRecipientWstETHBalance = expectedWstETHTransferred;
        assertEq(actualRecipientWstETHBalance, expectedRecipientWstETHBalance, "recipient wstETH balance in adapter");
    }
}
