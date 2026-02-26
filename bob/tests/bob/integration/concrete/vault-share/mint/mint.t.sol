// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Mint_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.BobVaultShare_OnlySablierBob.selector, users.depositor, address(bob))
        );
        defaultShareToken.mint(vaultIds.defaultVault, users.depositor, DEPOSIT_AMOUNT);
    }

    function test_RevertWhen_ProvidedVaultIDDoesNotMatch() external whenCallerBob {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.BobVaultShare_VaultIdMismatch.selector, vaultIds.settledVault, vaultIds.defaultVault
            )
        );
        defaultShareToken.mint(vaultIds.settledVault, users.depositor, DEPOSIT_AMOUNT);
    }

    function test_WhenProvidedVaultIDMatches() external whenCallerBob {
        uint256 balanceBefore = defaultShareToken.balanceOf(users.depositor);

        // It should not call onShareTransfer.
        vm.expectCall(address(bob), abi.encodeWithSelector(ISablierBob.onShareTransfer.selector), 0);

        // It should mint tokens.
        defaultShareToken.mint(vaultIds.defaultVault, users.depositor, DEPOSIT_AMOUNT);

        // It should mint the correct amount of tokens.
        uint256 actualBalance = defaultShareToken.balanceOf(users.depositor);
        uint256 expectedBalance = balanceBefore + DEPOSIT_AMOUNT;
        assertEq(actualBalance, expectedBalance, "mint");
    }
}
