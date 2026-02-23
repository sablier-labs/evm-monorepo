// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { BobVaultShare } from "src/BobVaultShare.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Metadata_BobVaultShare_Integration_Concrete_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      NAME
    //////////////////////////////////////////////////////////////////////////*/

    function test_Name_ReturnsConstructorValue() external {
        string memory expectedName = "Sablier Bob WETH Vault #1";

        BobVaultShare shareToken = new BobVaultShare({
            name_: expectedName,
            symbol_: "WETH-100-1792790393-1",
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.name(), expectedName, "name");
    }

    function test_Name_EmptyString() external {
        BobVaultShare shareToken =
            new BobVaultShare({ name_: "", symbol_: "TST", decimals_: 18, sablierBob: address(bob), vaultId: 1 });

        assertEq(shareToken.name(), "", "name");
    }

    function test_Name_LongString() external {
        string memory longName =
            "This is a very long token name that exceeds normal expectations for ERC20 token names but should still work";

        BobVaultShare shareToken =
            new BobVaultShare({ name_: longName, symbol_: "TST", decimals_: 18, sablierBob: address(bob), vaultId: 1 });

        assertEq(shareToken.name(), longName, "name");
    }

    function test_Name_SpecialCharacters() external {
        string memory specialName = unicode"Sablier Bob - Test #1 (100$) \u2764";

        BobVaultShare shareToken = new BobVaultShare({
            name_: specialName,
            symbol_: "TST",
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.name(), specialName, "name");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      SYMBOL
    //////////////////////////////////////////////////////////////////////////*/

    function test_Symbol_ReturnsConstructorValue() external {
        string memory expectedSymbol = "WETH-100-1792790393-1";

        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: expectedSymbol,
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.symbol(), expectedSymbol, "symbol");
    }

    function test_Symbol_StandardFormat() external {
        string memory expectedSymbol = "POL-100-1792790393-12";

        BobVaultShare shareToken = new BobVaultShare({
            name_: "Sablier Bob POL Vault #12",
            symbol_: expectedSymbol,
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 12
        });

        assertEq(shareToken.symbol(), expectedSymbol, "symbol");
    }

    function test_Symbol_EmptyString() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "",
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.symbol(), "", "symbol");
    }

    function test_Symbol_ShortString() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "T",
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.symbol(), "T", "symbol");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     DECIMALS
    //////////////////////////////////////////////////////////////////////////*/

    function test_Decimals_ReturnsConstructorValue() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "TST",
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.decimals(), 18, "decimals");
    }

    function test_Decimals_Six() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "TST",
            decimals_: 6,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.decimals(), 6, "decimals");
    }

    function test_Decimals_Eight() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "TST",
            decimals_: 8,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.decimals(), 8, "decimals");
    }

    function test_Decimals_Zero() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "TST",
            decimals_: 0,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.decimals(), 0, "decimals");
    }

    function test_Decimals_OverridesERC20Default() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "TST",
            decimals_: 12,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.decimals(), 12, "decimals");
    }

    /*//////////////////////////////////////////////////////////////////////////
                              COMBINED METADATA TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_AllMetadata_RealisticVaultShare() external {
        string memory expectedName = "Sablier Bob WETH Vault #42";
        string memory expectedSymbol = "WETH-5000-1767225600-42";

        BobVaultShare shareToken = new BobVaultShare({
            name_: expectedName,
            symbol_: expectedSymbol,
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 42
        });

        assertEq(shareToken.name(), expectedName, "name");
        assertEq(shareToken.symbol(), expectedSymbol, "symbol");
        assertEq(shareToken.decimals(), 18, "decimals");
        assertEq(shareToken.VAULT_ID(), 42, "VAULT_ID");
    }

    function test_AllMetadata_USDCVault() external {
        string memory expectedName = "Sablier Bob USDC Vault #1";
        string memory expectedSymbol = "USDC-2-1800000000-1";

        BobVaultShare shareToken = new BobVaultShare({
            name_: expectedName,
            symbol_: expectedSymbol,
            decimals_: 6,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.name(), expectedName, "name");
        assertEq(shareToken.symbol(), expectedSymbol, "symbol");
        assertEq(shareToken.decimals(), 6, "decimals");
    }
}
