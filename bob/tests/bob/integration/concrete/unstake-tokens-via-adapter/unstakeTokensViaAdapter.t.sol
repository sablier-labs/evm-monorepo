// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18, UNIT } from "@prb/math/src/UD60x18.sol";

import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract UnstakeTokensViaAdapter_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null(abi.encodeCall(bob.unstakeTokensViaAdapter, (vaultIds.nullVault)));
    }

    function test_RevertGiven_NoAdapter() external givenNotNull {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_VaultHasNoAdapter.selector, vaultIds.defaultVault));
        bob.unstakeTokensViaAdapter(vaultIds.defaultVault);
    }

    function test_RevertGiven_AlreadyUnstaked() external givenNotNull givenAdapter {
        // Warp past expiry and unstake tokens from adapter.
        vm.warp(EXPIRY + 1);
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_VaultAlreadyUnstaked.selector, vaultIds.vaultWithAdapter)
        );
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);
    }

    function test_RevertGiven_YieldTokenBalanceZero() external givenNotNull givenAdapter givenNotUnstaked {
        // Create a fresh adapter vault with no deposits (zero yield balance).
        uint256 vaultId = createVaultWithAdapter();
        vm.warp(EXPIRY + 1);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_UnstakeAmountZero.selector, vaultId));
        bob.unstakeTokensViaAdapter(vaultId);
    }

    function test_RevertWhen_SyncDoesNotChangeStatus()
        external
        givenNotNull
        givenAdapter
        givenNotUnstaked
        givenYieldTokenBalanceNotZero
        givenActive
    {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_VaultStillActive.selector, vaultIds.vaultWithAdapter));
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);
    }

    function test_WhenSyncChangesStatus()
        external
        givenNotNull
        givenAdapter
        givenNotUnstaked
        givenYieldTokenBalanceNotZero
        givenActive
    {
        // Simulate yield generation at settlement by lowering the exchange rate.
        uint128 newExchangeRate = 0.8e18;
        wstEth.setExchangeRate(newExchangeRate);

        // Set oracle price to target price so that the sync settles the vault.
        oracle.setPrice(TARGET_PRICE);

        uint128 expectedWethRedeemed = (WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT * 1e18) / newExchangeRate;

        // It should emit a {SyncPriceFromOracle} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.SyncPriceFromOracle({
            vaultId: vaultIds.vaultWithAdapter,
            oracle: oracle,
            latestPrice: TARGET_PRICE,
            syncedAt: getBlockTimestamp()
        });

        _testUnstakeTokensViaAdapter({ expectedWethRedeemed: expectedWethRedeemed });
    }

    function test_RevertWhen_SlippageExceedsTolerance()
        external
        givenNotNull
        givenAdapter
        givenNotUnstaked
        givenYieldTokenBalanceNotZero
        givenNotActive
    {
        // Set slippage in Curve mock to 10% so it exceeds adapter's slippage tolerance.
        // The mock expects basis points (1000 = 10%).
        UD60x18 newSlippage = UD60x18.wrap(0.1e18);
        curvePool.setActualSlippage(1000);

        // Warp past expiry.
        vm.warp(EXPIRY + 1);

        // Calculate expected minimum output with new slippage tolerance.
        uint256 minEthOut = ud(DEPOSIT_AMOUNT).mul(UNIT.sub(SLIPPAGE_TOLERANCE)).unwrap();
        uint256 actualOutput = ud(DEPOSIT_AMOUNT).mul(UNIT.sub(newSlippage)).unwrap();

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_SlippageExceeded.selector, minEthOut, actualOutput)
        );
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);
    }

    function test_WhenSlippageNotExceedTolerance()
        external
        givenNotNull
        givenAdapter
        givenNotUnstaked
        givenYieldTokenBalanceNotZero
        givenNotActive
    {
        // Simulate yield generation at settlement by lowering the exchange rate.
        uint128 newExchangeRate = 0.8e18;
        wstEth.setExchangeRate(newExchangeRate);

        vm.warp(EXPIRY + 1);

        uint128 expectedWethRedeemed = (WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT * 1e18) / newExchangeRate;

        _testUnstakeTokensViaAdapter({ expectedWethRedeemed: expectedWethRedeemed });
    }

    /// @dev Shared logic for testing unstakeTokensViaAdapter.
    function _testUnstakeTokensViaAdapter(uint128 expectedWethRedeemed) private {
        // It should emit an {UnstakeFullAmount} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.UnstakeFullAmount(
            vaultIds.vaultWithAdapter,
            WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            expectedWethRedeemed
        );

        // It should emit an {UnstakeFromAdapter} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.UnstakeFromAdapter(
            vaultIds.vaultWithAdapter,
            adapter,
            WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            expectedWethRedeemed
        );

        // It should transfer tokens back to Bob.
        expectCallToTransfer(weth, address(bob), expectedWethRedeemed);

        // It should return the amount received from the adapter.
        uint128 amountReceived = bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);
        assertEq(amountReceived, expectedWethRedeemed, "returnValue.amountReceived");

        // It should mark the vault as unstaked.
        assertFalse(bob.isStakedInAdapter(vaultIds.vaultWithAdapter), "isStakedInAdapter");

        // It should update storage in adapter.
        assertEq(
            adapter.getWethReceivedAfterUnstaking(vaultIds.vaultWithAdapter),
            expectedWethRedeemed,
            "wethReceivedAfterUnstaking"
        );
    }
}
