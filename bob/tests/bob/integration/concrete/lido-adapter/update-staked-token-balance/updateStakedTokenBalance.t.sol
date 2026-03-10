// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract UpdateStakedTokenBalance_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.depositor, address(bob))
        );
        adapter.updateStakedTokenBalance(
            vaultIds.vaultWithAdapter, users.depositor, users.newDepositor, DEPOSIT_AMOUNT, DEPOSIT_AMOUNT
        );
    }

    function test_RevertWhen_UserShareBalanceZero() external whenCallerBob {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_UserBalanceZero.selector, vaultIds.vaultWithAdapter, users.depositor
            )
        );
        adapter.updateStakedTokenBalance(
            vaultIds.vaultWithAdapter, users.depositor, users.newDepositor, DEPOSIT_AMOUNT, 0
        );
    }

    function test_RevertWhen_WstETHTransferAmountZero() external whenCallerBob whenUserShareBalanceNotZero {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_WstETHTransferAmountZero.selector,
                vaultIds.vaultWithAdapter,
                users.depositor,
                users.newDepositor
            )
        );
        adapter.updateStakedTokenBalance(
            vaultIds.vaultWithAdapter, users.depositor, users.newDepositor, 1, DEPOSIT_AMOUNT
        );
    }

    function test_WhenWstETHTransferAmountNotZero() external whenCallerBob whenUserShareBalanceNotZero {
        uint256 transferAmount = DEPOSIT_AMOUNT / 4;
        uint128 expectedWstETHTransfer = WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT / 4;

        // It should emit a {TransferStakedTokens} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.TransferStakedTokens({
            vaultId: vaultIds.vaultWithAdapter,
            from: users.depositor,
            to: users.newDepositor,
            amount: expectedWstETHTransfer
        });

        adapter.updateStakedTokenBalance(
            vaultIds.vaultWithAdapter, users.depositor, users.newDepositor, transferAmount, DEPOSIT_AMOUNT
        );

        // It should decrease sender wstETH balance.
        uint128 actualSenderWstETHBalance =
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor);
        uint128 expectedSenderWstETHBalance = WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT - expectedWstETHTransfer;
        assertEq(actualSenderWstETHBalance, expectedSenderWstETHBalance, "sender.wstETHBalance");

        // It should increase recipient wstETH balance.
        uint128 actualRecipientWstETHBalance =
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.newDepositor);
        uint128 expectedRecipientWstETHBalance = expectedWstETHTransfer;
        assertEq(actualRecipientWstETHBalance, expectedRecipientWstETHBalance, "recipient.wstETHBalance");
    }
}
