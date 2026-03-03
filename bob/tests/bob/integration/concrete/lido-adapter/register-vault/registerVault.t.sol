// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract RegisterVault_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.depositor, address(bob))
        );
        adapter.registerVault(vaultIds.vaultWithAdapter);
    }

    function test_WhenCallerBob() external whenCallerBob {
        // It should snapshot global yield fee against the vault ID.
        adapter.registerVault(vaultIds.vaultWithAdapter);
        assertEq(adapter.getVaultYieldFee(vaultIds.vaultWithAdapter), YIELD_FEE, "vaultYieldFee");
    }
}
