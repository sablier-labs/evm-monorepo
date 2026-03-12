// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                       SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Warp to Feb 1, 2026 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: FEB_1_2026 });

        initializeDefaultVaults();

        // Load the share token for the default vault into the default share token variable.
        defaultShareToken = bob.getShareToken(vaultIds.defaultVault);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Initializes the default vaults used in tests. The depositor enters each vault so that tests start with
    /// pre-existing shares.
    function initializeDefaultVaults() internal {
        // Create a default vault.
        vaultIds.defaultVault = createDefaultVault();
        bob.enter(vaultIds.defaultVault, DEPOSIT_AMOUNT);

        // Create a settled vault.
        vaultIds.settledVault = createDefaultVault();
        bob.enter(vaultIds.settledVault, DEPOSIT_AMOUNT);
        oracle.setPrice(TARGET_PRICE);
        bob.syncPriceFromOracle(vaultIds.settledVault);
        oracle.setPrice(CURRENT_PRICE); // Reset for other tests.

        // Create a vault with adapter.
        vaultIds.vaultWithAdapter = createVaultWithAdapter();
        setMsgSender(users.depositor);
        bob.enter(vaultIds.vaultWithAdapter, DEPOSIT_AMOUNT);

        // Set a null vault ID.
        vaultIds.nullVault = 1729;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COMMON-REVERT-TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a revert when the vault is expired.
    function expectRevert_EXPIRED(bytes memory callData) internal {
        // Expire the vault by moving block time past expiry.
        vm.warp(EXPIRY + 1);

        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "expired vault call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_VaultNotActive.selector, vaultIds.defaultVault),
            "expired vault call return data"
        );
    }

    /// @dev Expects a revert when the vault is null.
    function expectRevert_Null(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "null vault call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBobState_Null.selector, vaultIds.nullVault),
            "null vault call return data"
        );
    }

    /// @dev Expects a revert when the vault is settled.
    function expectRevert_SETTLED(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "settled vault call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_VaultNotActive.selector, vaultIds.settledVault),
            "settled vault call return data"
        );
    }
}
