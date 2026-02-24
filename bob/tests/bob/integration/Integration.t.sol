// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Set depositor as the caller for vault creation and deposits.
        setMsgSender(users.depositor);

        initializeDefaultVaults();

        // Set depositor as the default caller.
        setMsgSender(users.depositor);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZE-FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Initializes the default vaults used in tests. The depositor enters each vault so that tests
    /// start with pre-existing shares.
    function initializeDefaultVaults() internal {
        // Create a default vault (WETH, no adapter) and have depositor enter.
        vaultIds.defaultVault = createDefaultVault();
        bob.enter(vaultIds.defaultVault, DEPOSIT_AMOUNT);

        // Create a settled vault (WETH, no adapter) — depositor must enter BEFORE settlement.
        vaultIds.settledVault = createDefaultVault();
        bob.enter(vaultIds.settledVault, DEPOSIT_AMOUNT);
        oracle.setPrice(TARGET_PRICE);
        bob.syncPriceFromOracle(vaultIds.settledVault);
        oracle.setPrice(CURRENT_PRICE); // Reset for other tests.

        // Create a vault with adapter (must come after non-adapter vaults to avoid adapter auto-assignment).
        vaultIds.vaultWithAdapter = createVaultWithAdapter();
        bob.enter(vaultIds.vaultWithAdapter, DEPOSIT_AMOUNT);

        // Set a null vault ID (one that doesn't exist).
        vaultIds.nullVault = 1729;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COMMON-REVERT-TESTS
    //////////////////////////////////////////////////////////////////////////*/

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
}
