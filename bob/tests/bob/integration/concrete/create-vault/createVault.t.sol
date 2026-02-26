// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Bob } from "src/types/Bob.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract CreateVault_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_TokenZero() external {
        // It should revert.
        vm.expectRevert(Errors.SablierBob_TokenAddressZero.selector);
        bob.createVault({ token: IERC20(address(0)), oracle: oracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });
    }

    function test_RevertWhen_NativeToken() external whenTokenNotZero {
        // Set the native token.
        setMsgSender(address(comptroller));
        bob.setNativeToken(address(weth));

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_ForbidNativeToken.selector, address(weth)));
        bob.createVault({ token: weth, oracle: oracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });
    }

    function test_RevertWhen_ExpiryInPast() external whenTokenNotZero whenNotNativeToken {
        uint40 expiry = getBlockTimestamp() - 1;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_ExpiryNotInFuture.selector, expiry, getBlockTimestamp())
        );
        bob.createVault({ token: weth, oracle: oracle, expiry: expiry, targetPrice: TARGET_PRICE });
    }

    function test_RevertWhen_ExpiryInPresent() external whenTokenNotZero whenNotNativeToken {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierBob_ExpiryNotInFuture.selector, getBlockTimestamp(), getBlockTimestamp()
            )
        );
        bob.createVault({ token: weth, oracle: oracle, expiry: getBlockTimestamp(), targetPrice: TARGET_PRICE });
    }

    function test_RevertWhen_TargetPriceZero() external whenTokenNotZero whenNotNativeToken whenExpiryInFuture {
        // It should revert.
        vm.expectRevert(Errors.SablierBob_TargetPriceZero.selector);
        bob.createVault({ token: weth, oracle: oracle, expiry: EXPIRY, targetPrice: 0 });
    }

    function test_RevertWhen_TargetPriceNotExceedOraclePrice()
        external
        whenTokenNotZero
        whenNotNativeToken
        whenExpiryInFuture
        whenTargetPriceNotZero
    {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_TargetPriceTooLow.selector, CURRENT_PRICE, CURRENT_PRICE)
        );
        bob.createVault({ token: weth, oracle: oracle, expiry: EXPIRY, targetPrice: CURRENT_PRICE });
    }

    function test_GivenNoAdapter()
        external
        whenTokenNotZero
        whenNotNativeToken
        whenExpiryInFuture
        whenTargetPriceNotZero
        whenTargetPriceExceedsOraclePrice
    {
        // Clear the default adapter for WETH so the vault has no adapter.
        setMsgSender(address(comptroller));
        bob.setDefaultAdapter(weth, ISablierBobAdapter(address(0)));

        _testCreateVault({ expectedAdapter: ISablierBobAdapter(address(0)) });
    }

    function test_GivenAdapter()
        external
        whenTokenNotZero
        whenNotNativeToken
        whenExpiryInFuture
        whenTargetPriceNotZero
        whenTargetPriceExceedsOraclePrice
    {
        // Set a default adapter for WETH.
        setMsgSender(address(comptroller));
        bob.setDefaultAdapter(weth, adapter);

        _testCreateVault({ expectedAdapter: adapter });
    }

    /// @dev Shared logic for testing vault creation.
    function _testCreateVault(ISablierBobAdapter expectedAdapter) private {
        uint256 expectedVaultId = bob.nextVaultId();
        IBobVaultShare expectedShareToken = computeNextShareTokenAddress();
        string memory tokenSymbol = IERC20Metadata(address(weth)).symbol();
        uint8 tokenDecimals = IERC20Metadata(address(weth)).decimals();

        // It should emit a {CreateVault} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.CreateVault({
            vaultId: expectedVaultId,
            token: weth,
            oracle: oracle,
            adapter: expectedAdapter,
            shareToken: expectedShareToken,
            targetPrice: TARGET_PRICE,
            expiry: EXPIRY
        });

        // Create the vault.
        uint256 vaultId = bob.createVault({ token: weth, oracle: oracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });

        // It should create the vault.
        assertEq(vaultId, expectedVaultId, "vaultId");
        assertEq(bob.getExpiry(vaultId), EXPIRY, "expiry");
        assertEq(bob.getFirstDepositTime(vaultId, users.depositor), 0, "firstDepositTime");
        assertEq(bob.getLastSyncedAt(vaultId), getBlockTimestamp(), "lastSyncedAt");
        assertEq(bob.getLastSyncedPrice(vaultId), CURRENT_PRICE, "lastSyncedPrice");
        assertEq(address(bob.getOracle(vaultId)), address(oracle), "oracle");
        assertEq(bob.getTargetPrice(vaultId), TARGET_PRICE, "targetPrice");
        assertEq(address(bob.getUnderlyingToken(vaultId)), address(weth), "token");
        assertEq(address(bob.getAdapter(vaultId)), address(expectedAdapter), "adapter");

        // It should return the correct adapters.
        assertEq(address(bob.getAdapter(vaultId)), address(expectedAdapter), "getAdapter");
        assertEq(address(bob.getDefaultAdapterFor(weth)), address(expectedAdapter), "getDefaultAdapterFor");

        // It should deploy a share token.
        IBobVaultShare actualShareToken = bob.getShareToken(vaultId);
        assertEq(address(actualShareToken), address(expectedShareToken), "shareToken");
        assertEq(actualShareToken.SABLIER_BOB(), address(bob), "shareToken.SABLIER_BOB");
        assertEq(actualShareToken.VAULT_ID(), expectedVaultId, "shareToken.VAULT_ID");
        assertEq(actualShareToken.decimals(), tokenDecimals, "shareToken.decimals");
        assertEq(actualShareToken.name(), generateVaultName(tokenSymbol, vaultId), "shareToken.name");
        assertEq(
            actualShareToken.symbol(),
            generateVaultSymbol(tokenSymbol, TARGET_PRICE, EXPIRY, vaultId),
            "shareToken.symbol"
        );

        // If adapter is not zero, it should register the vault with the adapter.
        if (address(expectedAdapter) != address(0)) {
            assertTrue(bob.isStakedInAdapter(vaultId), "isStakedInAdapter");
            assertEq(expectedAdapter.getVaultYieldFee(vaultId), YIELD_FEE, "getVaultYieldFee");
        } else {
            assertFalse(bob.isStakedInAdapter(vaultId), "isStakedInAdapter");
        }

        // It should return the correct status.
        assertEq(bob.statusOf(vaultId), Bob.Status.ACTIVE);

        // It should bump the next vault ID.
        assertEq(bob.nextVaultId(), expectedVaultId + 1, "nextVaultId");
    }
}
