// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { Bob } from "src/types/Bob.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SyncPriceFromOracle_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_SyncPriceFromOracle_WhenPriceReachesTarget(uint128 newPrice)
        external
        givenNotNull
        givenACTIVEStatus
    {
        newPrice = boundUint128(newPrice, TARGET_PRICE, MAX_UINT128);

        // Set the oracle price at or above the target.
        oracle.setPrice(newPrice);

        // It should emit a {SyncPriceFromOracle} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.SyncPriceFromOracle({
            vaultId: vaultIds.defaultVault,
            oracle: oracle,
            latestPrice: newPrice,
            syncedAt: getBlockTimestamp()
        });

        uint128 latestPrice = bob.syncPriceFromOracle(vaultIds.defaultVault);

        // It should return the latest price.
        assertEq(latestPrice, newPrice, "returnValue.latestPrice");

        // It should update the last synced price.
        assertEq(bob.getLastSyncedPrice(vaultIds.defaultVault), newPrice, "lastSyncedPrice");

        // It should settle the vault.
        assertEq(bob.statusOf(vaultIds.defaultVault), Bob.Status.SETTLED);
    }

    function testFuzz_SyncPriceFromOracle(uint128 newPrice, uint40 timeJump) external givenNotNull givenACTIVEStatus {
        newPrice = boundUint128(newPrice, 1, TARGET_PRICE - 1);
        timeJump = boundUint40(timeJump, 0, EXPIRY - FEB_1_2026 - 1);

        // Advance time but stay before expiry.
        skip(timeJump);

        // Set the oracle price below the target.
        oracle.setPrice(newPrice);

        // It should emit a {SyncPriceFromOracle} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.SyncPriceFromOracle({
            vaultId: vaultIds.defaultVault,
            oracle: oracle,
            latestPrice: newPrice,
            syncedAt: getBlockTimestamp()
        });

        uint128 latestPrice = bob.syncPriceFromOracle(vaultIds.defaultVault);

        // It should return the latest price.
        assertEq(latestPrice, newPrice, "returnValue.latestPrice");

        // It should update the last synced price.
        assertEq(bob.getLastSyncedPrice(vaultIds.defaultVault), newPrice, "lastSyncedPrice");

        // It should update the last synced at timestamp.
        assertEq(bob.getLastSyncedAt(vaultIds.defaultVault), getBlockTimestamp(), "lastSyncedAt");

        // It should keep the vault active.
        assertEq(bob.statusOf(vaultIds.defaultVault), Bob.Status.ACTIVE);
    }
}
