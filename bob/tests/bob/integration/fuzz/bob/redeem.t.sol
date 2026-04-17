// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Redeem_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_RevertWhen_MsgValueNotZero(uint256 msgValue)
        external
        givenNotNull
        givenSETTLEDStatus
        whenSharesNotZero
        givenAdapter
    {
        msgValue = bound(msgValue, 1, 10 ether);

        // Settle the adapter vault.
        oracle.setPrice(TARGET_PRICE);
        bob.syncPriceFromOracle(vaultIds.vaultWithAdapter);

        vm.deal(users.depositor, msgValue);

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_MsgValueNotZero.selector, vaultIds.vaultWithAdapter));
        bob.redeem{ value: msgValue }(vaultIds.vaultWithAdapter);
    }

    function testFuzz_Redeem_GivenNoAdapter_GivenSETTLED(uint256 feeWei)
        external
        givenNotNull
        givenSETTLEDStatus
        whenSharesNotZero
    {
        feeWei = bound(feeWei, BOB_MIN_FEE_WEI, 10 ether);

        // Deal ETH to depositor for the fee.
        vm.deal(users.depositor, feeWei);

        uint256 expectedComptrollerBalance = address(comptroller).balance + feeWei;

        // It should emit a {Redeem} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Redeem({
            vaultId: vaultIds.settledVault,
            user: users.depositor,
            amountReceived: DEPOSIT_AMOUNT,
            sharesBurned: DEPOSIT_AMOUNT,
            fee: 0
        });

        // It should transfer tokens to depositor.
        expectCallToTransfer(weth, users.depositor, DEPOSIT_AMOUNT);

        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) =
            bob.redeem{ value: feeWei }(vaultIds.settledVault);

        // It should return the correct amounts.
        assertEq(transferAmount, DEPOSIT_AMOUNT, "transferAmount");
        assertEq(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield");

        // It should burn all shares.
        uint256 actualShareBalance = bob.getShareToken(vaultIds.settledVault).balanceOf(users.depositor);
        assertEq(actualShareBalance, 0, "shareBalance");

        // It should transfer the ETH fee to comptroller.
        uint256 actualComptrollerBalance = address(comptroller).balance;
        assertEq(actualComptrollerBalance, expectedComptrollerBalance, "comptrollerBalance");
    }

    function testFuzz_Redeem_GivenNoAdapter_GivenEXPIRED(uint40 timeJump, uint256 feeWei) external givenNotNull {
        timeJump = boundUint40(timeJump, 1, 365 days);
        feeWei = bound(feeWei, BOB_MIN_FEE_WEI, 10 ether);

        // Warp past expiry.
        vm.warp(EXPIRY + timeJump);

        // Record the synced values before redeem.
        uint128 expectedSyncedPrice = bob.getLastSyncedPrice(vaultIds.defaultVault);
        uint40 expectedSyncedAt = bob.getLastSyncedAt(vaultIds.defaultVault);
        uint256 expectedComptrollerBalance = address(comptroller).balance + feeWei;

        // Deal ETH to depositor for the fee.
        vm.deal(users.depositor, feeWei);

        // It should emit a {Redeem} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Redeem({
            vaultId: vaultIds.defaultVault,
            user: users.depositor,
            amountReceived: DEPOSIT_AMOUNT,
            sharesBurned: DEPOSIT_AMOUNT,
            fee: 0
        });

        // It should transfer tokens to depositor.
        expectCallToTransfer(weth, users.depositor, DEPOSIT_AMOUNT);

        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) =
            bob.redeem{ value: feeWei }(vaultIds.defaultVault);

        // It should return the correct amounts.
        assertEq(transferAmount, DEPOSIT_AMOUNT, "transferAmount");
        assertEq(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield");

        // It should not update the synced price.
        assertEq(bob.getLastSyncedPrice(vaultIds.defaultVault), expectedSyncedPrice, "syncedPrice unchanged");
        assertEq(bob.getLastSyncedAt(vaultIds.defaultVault), expectedSyncedAt, "syncedAt unchanged");

        // It should burn all shares.
        uint256 actualShareBalance = bob.getShareToken(vaultIds.defaultVault).balanceOf(users.depositor);
        assertEq(actualShareBalance, 0, "shareBalance");

        // It should transfer the ETH fee to comptroller.
        uint256 actualComptrollerBalance = address(comptroller).balance;
        assertEq(actualComptrollerBalance, expectedComptrollerBalance, "comptrollerBalance");
    }

    function testFuzz_Redeem_GivenNegativeYield(uint256 exchangeRateRaw)
        external
        givenAdapter
        givenNotNull
        whenSharesNotZero
        whenMsgValueZero
    {
        exchangeRateRaw = bound(exchangeRateRaw, WSTETH_WETH_EXCHANGE_RATE.unwrap(), 2e18);
        UD60x18 newExchangeRate = UD60x18.wrap(exchangeRateRaw);

        wstEth.setExchangeRate(newExchangeRate);

        // Set oracle price to target to settle the vault.
        oracle.setPrice(TARGET_PRICE);

        uint128 expectedWethRedeemed = expectedWethFromWstEth(WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT, newExchangeRate);

        // It should emit a {Redeem} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Redeem({
            vaultId: vaultIds.vaultWithAdapter,
            user: users.depositor,
            amountReceived: expectedWethRedeemed,
            sharesBurned: DEPOSIT_AMOUNT,
            fee: 0
        });

        // It should transfer tokens to depositor.
        expectCallToTransfer(weth, users.depositor, expectedWethRedeemed);

        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) = bob.redeem(vaultIds.vaultWithAdapter);

        // It should return the correct amounts.
        assertEq(transferAmount, expectedWethRedeemed, "transferAmount");
        assertLe(transferAmount, DEPOSIT_AMOUNT, "transferAmount <= depositAmount");
        assertEq(feeAmountDeductedFromYield, 0, "feeAmountDeductedFromYield");

        // It should set isStakedInAdapter to false.
        assertFalse(bob.isStakedInAdapter(vaultIds.vaultWithAdapter), "isStakedInAdapter");

        // It should burn all shares.
        uint256 actualShareBalance = bob.getShareToken(vaultIds.vaultWithAdapter).balanceOf(users.depositor);
        assertEq(actualShareBalance, 0, "shareBalance");

        // It should not transfer any fee to comptroller.
        assertEq(weth.balanceOf(address(comptroller)), 0, "comptrollerWethBalance");
    }

    function testFuzz_Redeem(uint256 exchangeRateRaw)
        external
        givenAdapter
        givenNotNull
        whenSharesNotZero
        whenMsgValueZero
    {
        exchangeRateRaw = bound(exchangeRateRaw, 0.1e18, 0.89e18);
        UD60x18 newExchangeRate = UD60x18.wrap(exchangeRateRaw);

        wstEth.setExchangeRate(newExchangeRate);

        // Set oracle price to target to settle the vault.
        oracle.setPrice(TARGET_PRICE);

        uint128 expectedWethRedeemed = expectedWethFromWstEth(WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT, newExchangeRate);
        (uint128 expectedComptrollerFee, uint128 expectedUserWeth) =
            calculateYieldBreakdown(expectedWethRedeemed, DEPOSIT_AMOUNT, YIELD_FEE);

        // It should emit a {Redeem} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Redeem({
            vaultId: vaultIds.vaultWithAdapter,
            user: users.depositor,
            amountReceived: expectedUserWeth,
            sharesBurned: DEPOSIT_AMOUNT,
            fee: expectedComptrollerFee
        });

        // It should transfer tokens to depositor.
        expectCallToTransfer(weth, users.depositor, expectedUserWeth);

        if (expectedComptrollerFee > 0) {
            // It should transfer the yield fee to comptroller.
            expectCallToTransfer(weth, address(comptroller), expectedComptrollerFee);
        }

        (uint128 transferAmount, uint128 feeAmountDeductedFromYield) = bob.redeem(vaultIds.vaultWithAdapter);

        // It should return the correct amounts.
        assertEq(transferAmount, expectedUserWeth, "transferAmount");
        assertEq(feeAmountDeductedFromYield, expectedComptrollerFee, "feeAmountDeductedFromYield");

        // It should set isStakedInAdapter to false.
        assertFalse(bob.isStakedInAdapter(vaultIds.vaultWithAdapter), "isStakedInAdapter");

        // It should burn all shares.
        uint256 actualShareBalance = bob.getShareToken(vaultIds.vaultWithAdapter).balanceOf(users.depositor);
        assertEq(actualShareBalance, 0, "shareBalance");

        // It should transfer yield fee to the comptroller.
        uint256 actualComptrollerWethBalance = weth.balanceOf(address(comptroller));
        assertEq(actualComptrollerWethBalance, expectedComptrollerFee, "comptrollerWethBalance");
    }
}
