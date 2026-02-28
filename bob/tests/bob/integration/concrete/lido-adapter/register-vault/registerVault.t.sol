// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract RegisterVault_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
        setMsgSender(users.newDepositor);
    }

    function test_RevertWhen_CallerNotSablierBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.newDepositor, address(bob))
        );
        adapter.registerVault(vaultIds.nullVault);
    }

    function test_WhenCallerSablierBob() external whenCallerBob {
        uint256 newVaultId = vaultIds.nullVault;

        // It should snapshot the current global yield fee.
        adapter.registerVault(newVaultId);
        assertEq(adapter.getVaultYieldFee(newVaultId).unwrap(), adapter.feeOnYield().unwrap(), "vaultYieldFee");
    }
}
