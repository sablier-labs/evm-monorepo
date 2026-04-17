// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Bob } from "src/types/Bob.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract CreateVault_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_RevertWhen_ExpiryNotInFuture(uint40 expiry) external whenTokenNotZero whenNotNativeToken {
        expiry = boundUint40(expiry, 0, getBlockTimestamp());

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_ExpiryNotInFuture.selector, expiry, getBlockTimestamp())
        );
        bob.createVault({ token: dai, oracle: oracle, expiry: expiry, targetPrice: TARGET_PRICE });
    }

    function testFuzz_RevertWhen_TargetPriceTooLow(uint128 targetPrice)
        external
        whenTokenNotZero
        whenNotNativeToken
        whenExpiryInFuture
        whenTargetPriceNotZero
    {
        targetPrice = boundUint128(targetPrice, 1, CURRENT_PRICE);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_TargetPriceTooLow.selector, targetPrice, CURRENT_PRICE)
        );
        bob.createVault({ token: dai, oracle: oracle, expiry: EXPIRY, targetPrice: targetPrice });
    }

    function testFuzz_CreateVault_GivenNoAdapter(
        uint128 targetPrice,
        uint40 expiry
    )
        external
        whenTokenNotZero
        whenNotNativeToken
        whenExpiryInFuture
        whenTargetPriceNotZero
        whenTargetPriceExceedsOraclePrice
    {
        targetPrice = boundUint128(targetPrice, CURRENT_PRICE + 1, MAX_UINT128);
        expiry = boundUint40(expiry, getBlockTimestamp() + 1, MAX_UINT40);

        // Set the oracle price so that the target price exceeds it.
        oracle.setPrice(targetPrice - 1);

        uint256 expectedVaultId = bob.nextVaultId();
        IBobVaultShare expectedShareToken = computeNextShareTokenAddress();

        // It should emit a {CreateVault} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.CreateVault({
            vaultId: expectedVaultId,
            token: dai,
            oracle: oracle,
            adapter: ISablierBobAdapter(address(0)),
            shareToken: expectedShareToken,
            targetPrice: targetPrice,
            expiry: expiry
        });

        // Use DAI which has no default adapter configured.
        uint256 vaultId = bob.createVault({ token: dai, oracle: oracle, expiry: expiry, targetPrice: targetPrice });

        // It should create the vault with correct state.
        assertEq(vaultId, expectedVaultId, "vaultId");
        assertEq(bob.getExpiry(vaultId), expiry, "expiry");
        assertEq(bob.getLastSyncedAt(vaultId), getBlockTimestamp(), "lastSyncedAt");
        assertEq(bob.getLastSyncedPrice(vaultId), targetPrice - 1, "lastSyncedPrice");
        assertEq(address(bob.getOracle(vaultId)), address(oracle), "oracle");
        assertEq(bob.getTargetPrice(vaultId), targetPrice, "targetPrice");
        assertEq(address(bob.getUnderlyingToken(vaultId)), address(dai), "token");
        assertEq(address(bob.getAdapter(vaultId)), address(0), "adapter");
        assertFalse(bob.isStakedInAdapter(vaultId), "isStakedInAdapter");
        assertEq(bob.statusOf(vaultId), Bob.Status.ACTIVE);

        // It should deploy a share token with correct metadata.
        IBobVaultShare actualShareToken = bob.getShareToken(vaultId);
        assertEq(address(actualShareToken), address(expectedShareToken), "shareToken");
        assertEq(actualShareToken.decimals(), 18, "shareToken.decimals");
        assertEq(actualShareToken.name(), generateVaultName("DAI", vaultId), "shareToken.name");
        assertEq(
            actualShareToken.symbol(), generateVaultSymbol("DAI", targetPrice, expiry, vaultId), "shareToken.symbol"
        );

        // It should bump the next vault ID.
        assertEq(bob.nextVaultId(), expectedVaultId + 1, "nextVaultId");
    }

    function testFuzz_CreateVault(
        uint128 targetPrice,
        uint40 expiry
    )
        external
        givenAdapter
        whenTokenNotZero
        whenNotNativeToken
        whenExpiryInFuture
        whenTargetPriceNotZero
        whenTargetPriceExceedsOraclePrice
    {
        targetPrice = boundUint128(targetPrice, CURRENT_PRICE + 1, MAX_UINT128);
        expiry = boundUint40(expiry, getBlockTimestamp() + 1, MAX_UINT40);

        // Set the oracle price so that the target price exceeds it.
        oracle.setPrice(targetPrice - 1);

        uint256 expectedVaultId = bob.nextVaultId();
        IBobVaultShare expectedShareToken = computeNextShareTokenAddress();

        // It should emit a {CreateVault} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.CreateVault({
            vaultId: expectedVaultId,
            token: weth,
            oracle: oracle,
            adapter: adapter,
            shareToken: expectedShareToken,
            targetPrice: targetPrice,
            expiry: expiry
        });

        // Use WETH which has a default adapter configured by setUp.
        uint256 vaultId = bob.createVault({ token: weth, oracle: oracle, expiry: expiry, targetPrice: targetPrice });

        // It should create the vault with correct state.
        assertEq(vaultId, expectedVaultId, "vaultId");
        assertEq(bob.getExpiry(vaultId), expiry, "expiry");
        assertEq(bob.getLastSyncedAt(vaultId), getBlockTimestamp(), "lastSyncedAt");
        assertEq(bob.getLastSyncedPrice(vaultId), targetPrice - 1, "lastSyncedPrice");
        assertEq(address(bob.getOracle(vaultId)), address(oracle), "oracle");
        assertEq(bob.getTargetPrice(vaultId), targetPrice, "targetPrice");
        assertEq(address(bob.getUnderlyingToken(vaultId)), address(weth), "token");
        assertEq(address(bob.getAdapter(vaultId)), address(adapter), "adapter");
        assertTrue(bob.isStakedInAdapter(vaultId), "isStakedInAdapter");
        assertEq(bob.statusOf(vaultId), Bob.Status.ACTIVE);

        // It should deploy a share token with correct metadata.
        IBobVaultShare actualShareToken = bob.getShareToken(vaultId);
        assertEq(address(actualShareToken), address(expectedShareToken), "shareToken");
        assertEq(actualShareToken.decimals(), 18, "shareToken.decimals");
        assertEq(actualShareToken.name(), generateVaultName("WETH", vaultId), "shareToken.name");
        assertEq(
            actualShareToken.symbol(), generateVaultSymbol("WETH", targetPrice, expiry, vaultId), "shareToken.symbol"
        );

        // It should register the vault with the adapter.
        assertEq(adapter.getVaultYieldFee(vaultId), YIELD_FEE, "getVaultYieldFee");

        // It should bump the next vault ID.
        assertEq(bob.nextVaultId(), expectedVaultId + 1, "nextVaultId");
    }
}
