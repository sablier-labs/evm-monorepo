// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

contract GetVaultYieldFee_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
        setMsgSender(users.newDepositor);
    }

    function test_GivenNoFeeChangesAfterCreation() external view {
        // It should return the snapshotted fee.
        assertEq(adapter.getVaultYieldFee(vaultIds.vaultWithAdapter).unwrap(), YIELD_FEE.unwrap(), "vaultYieldFee");
    }

    function test_GivenGlobalFeeChangedAfterCreation() external {
        uint256 initialVaultFee = adapter.getVaultYieldFee(vaultIds.vaultWithAdapter).unwrap();

        // Change the global yield fee.
        setMsgSender(address(comptroller));
        adapter.setYieldFee(MAX_YIELD_FEE);
        setMsgSender(users.newDepositor);

        // It should return the original snapshotted fee.
        assertEq(adapter.getVaultYieldFee(vaultIds.vaultWithAdapter).unwrap(), initialVaultFee, "vaultFee.unchanged");
        assertEq(adapter.feeOnYield().unwrap(), MAX_YIELD_FEE.unwrap(), "globalFee.changed");
    }
}
