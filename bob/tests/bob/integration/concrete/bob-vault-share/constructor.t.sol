// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { BobVaultShare } from "src/BobVaultShare.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Constructor_BobVaultShare_Integration_Concrete_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    string internal constant TEST_NAME = "Sablier Bob Test Share";
    string internal constant TEST_SYMBOL = "TEST-100-1234567890-1";
    uint8 internal constant TEST_DECIMALS = 18;
    uint256 internal constant TEST_VAULT_ID = 42;

    /*//////////////////////////////////////////////////////////////////////////
                                       TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_Constructor() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: TEST_NAME,
            symbol_: TEST_SYMBOL,
            decimals_: TEST_DECIMALS,
            sablierBob: address(bob),
            vaultId: TEST_VAULT_ID
        });

        assertEq(shareToken.SABLIER_BOB(), address(bob), "SABLIER_BOB");
        assertEq(shareToken.VAULT_ID(), TEST_VAULT_ID, "VAULT_ID");
        assertEq(shareToken.decimals(), TEST_DECIMALS, "decimals");
        assertEq(shareToken.name(), TEST_NAME, "name");
        assertEq(shareToken.symbol(), TEST_SYMBOL, "symbol");
        assertEq(shareToken.totalSupply(), 0, "totalSupply");
    }

    function test_Constructor_DifferentDecimals() external {
        BobVaultShare shareToken6 = new BobVaultShare({
            name_: TEST_NAME,
            symbol_: TEST_SYMBOL,
            decimals_: 6,
            sablierBob: address(bob),
            vaultId: TEST_VAULT_ID
        });
        assertEq(shareToken6.decimals(), 6, "decimals");

        BobVaultShare shareToken8 = new BobVaultShare({
            name_: TEST_NAME,
            symbol_: TEST_SYMBOL,
            decimals_: 8,
            sablierBob: address(bob),
            vaultId: TEST_VAULT_ID
        });
        assertEq(shareToken8.decimals(), 8, "decimals");
    }

    function test_Constructor_VaultIdOne() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: TEST_NAME,
            symbol_: TEST_SYMBOL,
            decimals_: TEST_DECIMALS,
            sablierBob: address(bob),
            vaultId: 1
        });
        assertEq(shareToken.VAULT_ID(), 1, "VAULT_ID");
    }

    function test_Constructor_LargeVaultId() external {
        uint256 largeVaultId = type(uint256).max;
        BobVaultShare shareToken = new BobVaultShare({
            name_: TEST_NAME,
            symbol_: TEST_SYMBOL,
            decimals_: TEST_DECIMALS,
            sablierBob: address(bob),
            vaultId: largeVaultId
        });
        assertEq(shareToken.VAULT_ID(), largeVaultId, "VAULT_ID");
    }
}
