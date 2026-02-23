// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { BobVaultShare as BobVaultShareContract } from "src/BobVaultShare.sol";
import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract BobVaultShare is Integration_Test {
    IBobVaultShare internal shareToken;
    uint8 internal constant TEST_DECIMALS = 18;
    uint256 internal constant TEST_VAULT_ID = 1;

    function setUp() public override {
        Integration_Test.setUp();
        setMsgSender(users.bob);

        shareToken = new BobVaultShareContract({
            name_: "Test Share Token",
            symbol_: "TST-100-12345-1",
            decimals_: TEST_DECIMALS,
            sablierBob: address(bob),
            vaultId: TEST_VAULT_ID
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      DECIMALS
    //////////////////////////////////////////////////////////////////////////*/

    function test_Decimals() external view {
        assertEq(shareToken.decimals(), TEST_DECIMALS, "decimals");
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

        vm.stopPrank();
        vm.prank(address(bob));
        shareToken.mint(TEST_VAULT_ID, users.depositor, 100e18);

        assertEq(shareToken.balanceOf(users.depositor) - balanceBefore, 100e18, "mintAmount");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        BURN
    //////////////////////////////////////////////////////////////////////////*/

    function test_Burn_RevertWhen_CallerNotSablierBob() external {
        vm.stopPrank();
        vm.prank(address(bob));
        shareToken.mint(TEST_VAULT_ID, users.depositor, 100e18);

        // It should revert.
        vm.prank(users.depositor);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.BobVaultShare_OnlySablierBob.selector, users.depositor, address(bob))
        );
        shareToken.burn(TEST_VAULT_ID, users.depositor, 100e18);
    }

    function test_Burn_WhenCallerSablierBob() external {
        vm.stopPrank();
        vm.prank(address(bob));
        shareToken.mint(TEST_VAULT_ID, users.depositor, 100e18);

        uint256 balanceBefore = shareToken.balanceOf(users.depositor);

        vm.prank(address(bob));
        shareToken.burn(TEST_VAULT_ID, users.depositor, 100e18);

        assertEq(balanceBefore - shareToken.balanceOf(users.depositor), 100e18, "burnAmount");
    }
}
