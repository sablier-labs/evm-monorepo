// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract UpdateStakedTokenBalance_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
        setMsgSender(users.newDepositor);
    }

    function test_RevertWhen_CallerNotSablierBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.newDepositor, address(bob))
        );
        adapter.updateStakedTokenBalance(
            vaultIds.vaultWithAdapter, users.depositor, users.newDepositor, DEPOSIT_AMOUNT, DEPOSIT_AMOUNT
        );
    }

    function test_RevertWhen_UserShareBalanceBeforeTransferZero() external whenCallerBob {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_UserBalanceZero.selector, vaultIds.vaultWithAdapter, users.depositor
            )
        );
        adapter.updateStakedTokenBalance(
            vaultIds.vaultWithAdapter,
            users.depositor,
            users.newDepositor,
            DEPOSIT_AMOUNT,
            0 // userShareBalanceBeforeTransfer = 0
        );
    }

    function test_WhenUserShareBalanceBeforeTransferNotZero() external whenCallerBob {
        uint256 transferAmount = DEPOSIT_AMOUNT / 2;
        uint128 senderBalanceBefore = adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor);
        uint128 recipientBalanceBefore =
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.newDepositor);

        // Calculate expected wstETH transfer amount.
        uint128 expectedWstETHTransfer = uint128(uint256(senderBalanceBefore) * transferAmount / DEPOSIT_AMOUNT);

        // It should emit a {TransferStakedTokens} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.TransferStakedTokens(
            vaultIds.vaultWithAdapter,
            users.depositor,
            users.newDepositor,
            expectedWstETHTransfer
        );

        adapter.updateStakedTokenBalance(
            vaultIds.vaultWithAdapter, users.depositor, users.newDepositor, transferAmount, DEPOSIT_AMOUNT
        );

        // It should decrease sender wstETH balance.
        assertEq(
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor),
            senderBalanceBefore - expectedWstETHTransfer,
            "sender.wstETHBalance"
        );

        // It should increase recipient wstETH balance.
        assertEq(
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.newDepositor),
            recipientBalanceBefore + expectedWstETHTransfer,
            "recipient.wstETHBalance"
        );
    }
}
