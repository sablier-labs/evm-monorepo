// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract RegisterVault_AaveAdapter_Integration_Concrete_Test is Integration_Test {
    uint256 internal daiVaultId;
    uint256 internal unregisteredWbtcVaultId;

    function setUp() public override {
        Integration_Test.setUp();

        // Create a vault with DAI (not registered in the Aave mock data provider).
        daiVaultId = bob.createVault({ token: dai, oracle: oracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });

        // Create a WBTC vault without an adapter so it is not yet registered with the Aave adapter.
        unregisteredWbtcVaultId =
            bob.createVault({ token: wbtc, oracle: oracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });
    }

    function test_RevertWhen_CallerNotBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierAaveAdapter_OnlySablierBob.selector, users.depositor, address(bob))
        );
        aaveAdapter.registerVault(vaultIds.vaultWithAaveAdapter);
    }

    function test_RevertWhen_TokenNotSupportedByAave() external whenCallerBob {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierAaveAdapter_TokenNotSupportedByAave.selector, address(dai))
        );
        aaveAdapter.registerVault(daiVaultId);
    }

    function test_WhenTokenSupportedByAave() external whenCallerBob {
        // Register the unregistered WBTC vault (WBTC is supported by Aave).
        aaveAdapter.registerVault(unregisteredWbtcVaultId);

        // It should snapshot global yield fee against the vault ID.
        assertEq(aaveAdapter.getVaultYieldFee(unregisteredWbtcVaultId), YIELD_FEE, "vaultYieldFee");

        // It should approve Aave Pool to spend the token.
        assertEq(wbtc.allowance(address(aaveAdapter), address(aavePool)), type(uint128).max, "aavePool allowance");
    }
}
