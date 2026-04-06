// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract UpdateStakedTokenBalance_AaveAdapter_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierAaveAdapter_OnlySablierBob.selector, users.depositor, address(bob))
        );
        aaveAdapter.updateStakedTokenBalance(
            vaultIds.vaultWithAaveAdapter, users.depositor, users.newDepositor, WBTC_DEPOSIT_AMOUNT, WBTC_DEPOSIT_AMOUNT
        );
    }

    function test_RevertWhen_UserShareBalanceZero() external whenCallerBob {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierAaveAdapter_UserBalanceZero.selector, vaultIds.vaultWithAaveAdapter, users.depositor
            )
        );
        aaveAdapter.updateStakedTokenBalance(
            vaultIds.vaultWithAaveAdapter, users.depositor, users.newDepositor, WBTC_DEPOSIT_AMOUNT, 0
        );
    }

    function test_RevertWhen_ScaledTransferAmountZero() external whenCallerBob whenUserShareBalanceNotZero {
        // With scaled balance = WBTC_DEPOSIT_AMOUNT and shareAmountTransferred = 1, the result rounds to zero only if
        // userShareBalanceBeforeTransfer > scaled balance.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierAaveAdapter_ScaledTransferAmountZero.selector,
                vaultIds.vaultWithAaveAdapter,
                users.depositor,
                users.newDepositor
            )
        );
        aaveAdapter.updateStakedTokenBalance(
            vaultIds.vaultWithAaveAdapter, users.depositor, users.newDepositor, 1, WBTC_DEPOSIT_AMOUNT + 1
        );
    }

    function test_WhenScaledTransferAmountNotZero() external whenCallerBob whenUserShareBalanceNotZero {
        uint256 transferAmount = WBTC_DEPOSIT_AMOUNT / 4;
        uint256 expectedScaledTransfer = WBTC_DEPOSIT_AMOUNT / 4; // At normalizedIncome = 1e27, scaled = actual.

        // It should emit a {TransferStakedTokens} event.
        vm.expectEmit({ emitter: address(aaveAdapter) });
        emit ISablierBobAdapter.TransferStakedTokens({
            vaultId: vaultIds.vaultWithAaveAdapter,
            from: users.depositor,
            to: users.newDepositor,
            amount: expectedScaledTransfer
        });

        aaveAdapter.updateStakedTokenBalance(
            vaultIds.vaultWithAaveAdapter, users.depositor, users.newDepositor, transferAmount, WBTC_DEPOSIT_AMOUNT
        );

        // It should decrease sender scaled balance.
        uint256 actualSenderScaled =
            aaveAdapter.getATokenUserScaledBalance(vaultIds.vaultWithAaveAdapter, users.depositor);
        uint256 expectedSenderScaled = WBTC_DEPOSIT_AMOUNT - expectedScaledTransfer;
        assertEq(actualSenderScaled, expectedSenderScaled, "sender.scaledBalance");

        // It should increase recipient scaled balance.
        uint256 actualRecipientScaled =
            aaveAdapter.getATokenUserScaledBalance(vaultIds.vaultWithAaveAdapter, users.newDepositor);
        uint256 expectedRecipientScaled = expectedScaledTransfer;
        assertEq(actualRecipientScaled, expectedRecipientScaled, "recipient.scaledBalance");
    }
}
