// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SyncPriceFromOracle_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null(abi.encodeCall(bob.syncPriceFromOracle, (vaultIds.nullVault)));
    }

    function test_RevertGiven_Settled() external givenNotNull {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_VaultNotActive.selector, vaultIds.settledVault));
        bob.syncPriceFromOracle(vaultIds.settledVault);
    }

    function test_RevertGiven_Expired() external givenNotNull {
        vm.warp(EXPIRY + 1);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_VaultNotActive.selector, vaultIds.defaultVault));
        bob.syncPriceFromOracle(vaultIds.defaultVault);
    }

    function test_WhenLatestPriceZero() external givenNotNull givenActive {
        uint128 expectedLastSyncedPrice = bob.getLastSyncedPrice(vaultIds.defaultVault);
        uint40 expectedLastSyncedAt = bob.getLastSyncedAt(vaultIds.defaultVault);

        // Set the latest price to zero on oracle.
        oracle.setPrice(0);

        uint128 latestPrice = bob.syncPriceFromOracle(vaultIds.defaultVault);
        assertEq(latestPrice, 0, "returnValue.latestPrice");

        // It should do nothing.
        uint128 actualLastSyncedPrice = bob.getLastSyncedPrice(vaultIds.defaultVault);
        assertEq(actualLastSyncedPrice, expectedLastSyncedPrice, "lastSyncedPrice");

        // It should update the last synced at timestamp.
        uint40 actualLastSyncedAt = bob.getLastSyncedAt(vaultIds.defaultVault);
        assertEq(actualLastSyncedAt, expectedLastSyncedAt, "lastSyncedAt");
    }

    function test_WhenLatestPriceNotZero() external givenNotNull givenActive {
        oracle.setPrice(TARGET_PRICE);

        // It should emit a {SyncPriceFromOracle} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.SyncPriceFromOracle({
            vaultId: vaultIds.defaultVault,
            oracle: oracle,
            latestPrice: TARGET_PRICE,
            syncedAt: getBlockTimestamp()
        });

        uint128 latestPrice = bob.syncPriceFromOracle(vaultIds.defaultVault);

        // It should return the latest price.
        assertEq(latestPrice, TARGET_PRICE, "returnValue.latestPrice");

        // It should update the last synced price.
        uint128 actualLastSyncedPrice = bob.getLastSyncedPrice(vaultIds.defaultVault);
        assertEq(actualLastSyncedPrice, TARGET_PRICE, "lastSyncedPrice");

        // It should update the last synced at timestamp.
        uint40 actualLastSyncedAt = bob.getLastSyncedAt(vaultIds.defaultVault);
        assertEq(actualLastSyncedAt, getBlockTimestamp(), "lastSyncedAt");
    }
}
