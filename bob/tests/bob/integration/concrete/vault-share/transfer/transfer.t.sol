// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Transfer_Integration_Concrete_Test is Integration_Test {
    function test_GivenNoAdapter() external {
        uint256 senderBalanceBefore = defaultShareToken.balanceOf(users.depositor);
        uint256 recipientBalanceBefore = defaultShareToken.balanceOf(users.newDepositor);

        // It should call onShareTransfer on Bob.
        vm.expectCall(address(bob), abi.encodeWithSelector(ISablierBob.onShareTransfer.selector), 1);

        // It should not call updateStakedTokenBalance on adapter.
        vm.expectCall(address(adapter), abi.encodeWithSelector(ISablierBobAdapter.updateStakedTokenBalance.selector), 0);

        // It should transfer tokens.
        defaultShareToken.transfer(users.newDepositor, DEPOSIT_AMOUNT);

        // It should transfer the correct amount of tokens.
        uint256 actualSenderBalance = defaultShareToken.balanceOf(users.depositor);
        uint256 expectedSenderBalance = senderBalanceBefore - DEPOSIT_AMOUNT;
        assertEq(actualSenderBalance, expectedSenderBalance, "sender balance");

        uint256 actualRecipientBalance = defaultShareToken.balanceOf(users.newDepositor);
        uint256 expectedRecipientBalance = recipientBalanceBefore + DEPOSIT_AMOUNT;
        assertEq(actualRecipientBalance, expectedRecipientBalance, "recipient balance");
    }

    function test_GivenAdapter() external {
        IBobVaultShare shareTokenForVaultWithAdapter = bob.getShareToken(vaultIds.vaultWithAdapter);

        uint256 senderBalanceBefore = shareTokenForVaultWithAdapter.balanceOf(users.depositor);
        uint256 recipientBalanceBefore = shareTokenForVaultWithAdapter.balanceOf(users.newDepositor);

        // It should call onShareTransfer on Bob.
        vm.expectCall(address(bob), abi.encodeWithSelector(ISablierBob.onShareTransfer.selector), 1);

        // It should call updateStakedTokenBalance on adapter.
        vm.expectCall(address(adapter), abi.encodeWithSelector(ISablierBobAdapter.updateStakedTokenBalance.selector), 1);

        // It should transfer tokens.
        shareTokenForVaultWithAdapter.transfer(users.newDepositor, DEPOSIT_AMOUNT);

        // It should transfer the correct amount of tokens.
        uint256 actualSenderBalance = shareTokenForVaultWithAdapter.balanceOf(users.depositor);
        uint256 expectedSenderBalance = senderBalanceBefore - DEPOSIT_AMOUNT;
        assertEq(actualSenderBalance, expectedSenderBalance, "sender balance");

        uint256 actualRecipientBalance = shareTokenForVaultWithAdapter.balanceOf(users.newDepositor);
        uint256 expectedRecipientBalance = recipientBalanceBefore + DEPOSIT_AMOUNT;
        assertEq(actualRecipientBalance, expectedRecipientBalance, "recipient balance");
    }
}
