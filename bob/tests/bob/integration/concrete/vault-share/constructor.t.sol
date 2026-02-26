// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../Integration.t.sol";

contract Constructor_VaultShare_Integration_Concrete_Test is Integration_Test {
    function test_Constructor() external {
        // It should set the bob address.
        assertEq(defaultShareToken.SABLIER_BOB(), address(bob), "bob");

        // It should set the vault ID.
        assertEq(defaultShareToken.VAULT_ID(), 1, "vaultId");

        // It should set the decimals.
        assertEq(defaultShareToken.decimals(), WETH_DECIMALS, "decimals");

        // It should set the name.
        assertEq(defaultShareToken.name(), SHARE_TOKEN_NAME, "name");

        // It should set the symbol.
        assertEq(defaultShareToken.symbol(), SHARE_TOKEN_SYMBOL, "symbol");

        // It should have the correct total supply.
        assertEq(defaultShareToken.totalSupply(), DEPOSIT_AMOUNT, "totalSupply");
    }
}
