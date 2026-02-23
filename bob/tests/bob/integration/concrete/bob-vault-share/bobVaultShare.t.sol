// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { BobVaultShare } from "src/BobVaultShare.sol";
import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract BobVaultShare_Integration_Concrete_Test is Integration_Test {
    IBobVaultShare internal shareToken;

    string internal constant TEST_NAME = "Sablier Bob WETH Vault #1";
    string internal constant TEST_SYMBOL = "WETH-100-12345-1";
    uint8 internal constant TEST_DECIMALS = 18;
    uint256 internal constant TEST_VAULT_ID = 1;

    function setUp() public override {
        Integration_Test.setUp();
        setMsgSender(users.bob);

        shareToken = new BobVaultShare({
            name_: TEST_NAME,
            symbol_: TEST_SYMBOL,
            decimals_: TEST_DECIMALS,
            sablierBob: address(bob),
            vaultId: TEST_VAULT_ID
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    function test_Constructor_WhenDeployed() external view {
        // It should set the SABLIER_BOB address.
        assertEq(shareToken.SABLIER_BOB(), address(bob), "SABLIER_BOB");

        // It should set the VAULT_ID.
        assertEq(shareToken.VAULT_ID(), TEST_VAULT_ID, "VAULT_ID");

        // It should set the decimals.
        assertEq(shareToken.decimals(), TEST_DECIMALS, "decimals");

        // It should set the name.
        assertEq(shareToken.name(), TEST_NAME, "name");

        // It should set the symbol.
        assertEq(shareToken.symbol(), TEST_SYMBOL, "symbol");

        // It should have zero total supply.
        assertEq(shareToken.totalSupply(), 0, "totalSupply");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        MINT
    //////////////////////////////////////////////////////////////////////////*/

    function test_Mint_RevertWhen_CallerNotSablierBob() external {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.BobVaultShare_OnlySablierBob.selector, users.bob, address(bob)));
        shareToken.mint(TEST_VAULT_ID, users.bob, 100e18);
    }

    function test_Mint_WhenCallerSablierBob() external {
        uint256 balanceBefore = shareToken.balanceOf(users.depositor);

        // It should increase the balance of the recipient.
        setMsgSender(address(bob));
        shareToken.mint(TEST_VAULT_ID, users.depositor, 100e18);

        uint256 actualMinted = shareToken.balanceOf(users.depositor) - balanceBefore;
        assertEq(actualMinted, 100e18, "mintAmount");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        BURN
    //////////////////////////////////////////////////////////////////////////*/

    function test_Burn_RevertWhen_CallerNotSablierBob() external {
        // Mint first so there's something to burn.
        setMsgSender(address(bob));
        shareToken.mint(TEST_VAULT_ID, users.depositor, 100e18);

        // It should revert.
        setMsgSender(users.depositor);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.BobVaultShare_OnlySablierBob.selector, users.depositor, address(bob))
        );
        shareToken.burn(TEST_VAULT_ID, users.depositor, 100e18);
    }

    function test_Burn_WhenCallerSablierBob() external {
        setMsgSender(address(bob));
        shareToken.mint(TEST_VAULT_ID, users.depositor, 100e18);

        uint256 balanceBefore = shareToken.balanceOf(users.depositor);

        // It should decrease the balance of the owner.
        shareToken.burn(TEST_VAULT_ID, users.depositor, 100e18);

        uint256 actualBurned = balanceBefore - shareToken.balanceOf(users.depositor);
        assertEq(actualBurned, 100e18, "burnAmount");
    }
}
