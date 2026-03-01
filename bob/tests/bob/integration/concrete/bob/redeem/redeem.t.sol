// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Redeem_Integration_Concrete_Test is Integration_Test {
    UD60x18 internal newExchangeRate;

    function setUp() public override {
        Integration_Test.setUp();

        // Simulate yield generation at settlement by lowering the exchange rate.
        newExchangeRate = UD60x18.wrap(0.8e18);
        wstEth.setExchangeRate(newExchangeRate);
    }

    function test_RevertGiven_Null() external {
        expectRevert_Null(abi.encodeCall(bob.redeem, (vaultIds.nullVault)));
    }

    function test_RevertWhen_SyncNotChangeStatus() external givenNotNull givenACTIVEStatus {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_VaultStillActive.selector, vaultIds.defaultVault));
        bob.redeem{ value: BOB_MIN_FEE_WEI }(vaultIds.defaultVault);
    }

    function test_WhenSyncChangesStatus() external givenNotNull givenACTIVEStatus {
        // Set oracle price to target price so that the sync settles the vault.
        oracle.setPrice(TARGET_PRICE);

        // It should emit {SyncPriceFromOracle} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.SyncPriceFromOracle({
            vaultId: vaultIds.defaultVault,
            oracle: oracle,
            latestPrice: TARGET_PRICE,
            syncedAt: getBlockTimestamp()
        });

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

        // Redeem shares from the vault.
        bob.redeem{ value: BOB_MIN_FEE_WEI }(vaultIds.defaultVault);

        // It should burn all shares.
        uint256 actualShareBalance = bob.getShareToken(vaultIds.defaultVault).balanceOf(users.depositor);
        assertEq(actualShareBalance, 0, "shareBalance");

        // It should update the synced price.
        uint256 actualSyncedPrice = bob.getLastSyncedPrice(vaultIds.defaultVault);
        assertEq(actualSyncedPrice, TARGET_PRICE, "syncedPrice");
    }

    function test_GivenEXPIREDStatus() external givenNotNull {
        uint256 expectedSyncedPrice = bob.getLastSyncedPrice(vaultIds.defaultVault);
        uint256 expectedSyncedAt = bob.getLastSyncedAt(vaultIds.defaultVault);

        // Warp past expiry.
        vm.warp(EXPIRY + 1);

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

        // Redeem shares from the vault.
        bob.redeem{ value: BOB_MIN_FEE_WEI }(vaultIds.defaultVault);

        // It should not update the synced price.
        uint256 actualSyncedAt = bob.getLastSyncedAt(vaultIds.defaultVault);
        assertEq(actualSyncedAt, expectedSyncedAt, "syncedAt unchanged");

        uint256 actualSyncedPrice = bob.getLastSyncedPrice(vaultIds.defaultVault);
        assertEq(actualSyncedPrice, expectedSyncedPrice, "syncedPrice unchanged");

        // It should burn all shares.
        uint256 actualShareBalance = bob.getShareToken(vaultIds.defaultVault).balanceOf(users.depositor);
        assertEq(actualShareBalance, 0, "shareBalance");
    }

    function test_RevertWhen_SharesZero() external givenNotNull givenSETTLEDStatus {
        setMsgSender(users.eve);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_NoSharesToRedeem.selector, vaultIds.settledVault, users.eve)
        );
        bob.redeem{ value: BOB_MIN_FEE_WEI }(vaultIds.settledVault);
    }

    function test_RevertWhen_FeeNotExceedMinFee()
        external
        givenNotNull
        givenSETTLEDStatus
        whenSharesNotZero
        givenNoAdapter
    {
        uint256 minFeeWei = BOB_MIN_FEE_WEI - 1;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_InsufficientFeePayment.selector, minFeeWei, BOB_MIN_FEE_WEI)
        );
        bob.redeem{ value: minFeeWei }(vaultIds.settledVault);
    }

    function test_WhenFeeExceedsMinFee() external givenNotNull givenSETTLEDStatus whenSharesNotZero givenNoAdapter {
        uint256 expectedComptrollerBalance = address(comptroller).balance + BOB_MIN_FEE_WEI;
        uint256 expectedSyncedPrice = bob.getLastSyncedPrice(vaultIds.settledVault);
        uint256 expectedSyncedAt = bob.getLastSyncedAt(vaultIds.settledVault);

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

        // Redeem shares from the vault.
        (uint256 transferredAmount, uint256 feeAmount) = bob.redeem{ value: BOB_MIN_FEE_WEI }(vaultIds.settledVault);

        // It should return the correct amounts.
        assertEq(transferredAmount, DEPOSIT_AMOUNT, "returnValue.transferredAmount");
        assertEq(feeAmount, 0, "returnValue.feeAmount");

        // It should not update the synced price.
        uint256 actualSyncedAt = bob.getLastSyncedAt(vaultIds.settledVault);
        assertEq(actualSyncedAt, expectedSyncedAt, "syncedAt unchanged");

        uint256 actualSyncedPrice = bob.getLastSyncedPrice(vaultIds.settledVault);
        assertEq(actualSyncedPrice, expectedSyncedPrice, "syncedPrice unchanged");

        // It should transfer fee to comptroller.
        uint256 actualComptrollerBalance = address(comptroller).balance;
        assertEq(actualComptrollerBalance, expectedComptrollerBalance, "comptrollerBalance");

        // It should burn all shares.
        uint256 actualShareBalance = bob.getShareToken(vaultIds.settledVault).balanceOf(users.depositor);
        assertEq(actualShareBalance, 0, "shareBalance");
    }

    function test_GivenStakedInAdapter() external givenNotNull givenSETTLEDStatus whenSharesNotZero givenAdapter {
        // Set oracle price to target price so that the sync settles the vault.
        oracle.setPrice(TARGET_PRICE);

        uint128 expectedWethRedeemed = ud(WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT).div(newExchangeRate).intoUint128();
        uint128 expectedYield = expectedWethRedeemed - DEPOSIT_AMOUNT;
        uint128 expectedComptrollerFee = ud(expectedYield).mul(YIELD_FEE).intoUint128();
        uint128 expectedUserWeth = expectedWethRedeemed - expectedComptrollerFee;

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

        // It should transfer fee to comptroller.
        expectCallToTransfer(weth, address(comptroller), expectedComptrollerFee);

        // Redeem shares from the vault.
        (uint256 transferredAmount, uint256 feeAmount) = bob.redeem{ value: BOB_MIN_FEE_WEI }(vaultIds.vaultWithAdapter);

        assertEq(transferredAmount, expectedUserWeth, "transferredAmount");
        assertEq(feeAmount, expectedComptrollerFee, "feeAmount");

        // It should trigger unstake via adapter.
        assertEq(
            adapter.getWethReceivedAfterUnstaking(vaultIds.vaultWithAdapter),
            expectedWethRedeemed,
            "wethReceivedAfterUnstaking"
        );

        // It should set isStakedInAdapter to false.
        assertFalse(bob.isStakedInAdapter(vaultIds.vaultWithAdapter), "isStakedInAdapter after");

        // It should burn all shares.
        uint256 actualShareBalance = bob.getShareToken(vaultIds.vaultWithAdapter).balanceOf(users.depositor);
        assertEq(actualShareBalance, 0, "shareBalance");

        // It should yield fee to the comptroller.
        uint256 actualComptrollerWethBalance = weth.balanceOf(address(comptroller));
        uint256 expectedComptrollerWethBalance = expectedComptrollerFee;
        assertEq(actualComptrollerWethBalance, expectedComptrollerWethBalance, "comptrollerWethBalance");
    }

    function test_GivenNotStakedInAdapter() external givenNotNull givenSETTLEDStatus whenSharesNotZero givenAdapter {
        // Settle the vault via price so status is SETTLED.
        oracle.setPrice(TARGET_PRICE);

        // Unstake first so the vault is no longer staked in the adapter.
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);

        uint128 expectedWethRedeemed = ud(WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT).div(newExchangeRate).intoUint128();
        uint128 expectedYield = expectedWethRedeemed - DEPOSIT_AMOUNT;
        uint128 expectedComptrollerFee = ud(expectedYield).mul(YIELD_FEE).intoUint128();
        uint128 expectedUserWeth = expectedWethRedeemed - expectedComptrollerFee;

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

        // It should transfer yield fee to comptroller.
        expectCallToTransfer(weth, address(comptroller), expectedComptrollerFee);

        // Redeem shares from the vault.
        (uint256 transferredAmount, uint256 feeAmount) = bob.redeem(vaultIds.vaultWithAdapter);

        assertEq(transferredAmount, expectedUserWeth, "transferredAmount");
        assertEq(feeAmount, expectedComptrollerFee, "feeAmount");

        // It should burn all shares.
        uint256 actualShareBalance = bob.getShareToken(vaultIds.vaultWithAdapter).balanceOf(users.depositor);
        assertEq(actualShareBalance, 0, "shareBalance");

        // It should transfer yield fee to the comptroller.
        uint256 actualComptrollerWethBalance = weth.balanceOf(address(comptroller));
        assertEq(actualComptrollerWethBalance, expectedComptrollerFee, "comptrollerWethBalance");
    }
}
