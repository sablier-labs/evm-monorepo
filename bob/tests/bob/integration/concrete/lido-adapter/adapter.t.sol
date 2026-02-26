// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract LidoAdapter_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
        setMsgSender(users.newDepositor);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        STAKE
    //////////////////////////////////////////////////////////////////////////*/

    function test_Stake_RevertWhen_CallerNotSablierBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.newDepositor, address(bob))
        );
        adapter.stake(1, users.newDepositor, 1 ether);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          UNSTAKE-FOR-USER-WITHIN-GRACE-PERIOD
    //////////////////////////////////////////////////////////////////////////*/

    function test_UnstakeForUserWithinGracePeriod_RevertWhen_CallerNotSablierBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.newDepositor, address(bob))
        );
        adapter.unstakeForUserWithinGracePeriod(1, users.newDepositor);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  UNSTAKE-FULL-AMOUNT
    //////////////////////////////////////////////////////////////////////////*/

    function test_UnstakeFullAmount_RevertWhen_CallerNotSablierBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.newDepositor, address(bob))
        );
        adapter.unstakeFullAmount(1);
    }

    /*//////////////////////////////////////////////////////////////////////////
                       CALCULATE-AMOUNT-TO-TRANSFER-WITH-YIELD
    //////////////////////////////////////////////////////////////////////////*/

    function test_CalculateAmountToTransferWithYield_GivenNoYieldBearingTokenBalance() external view {
        // It should return zero.
        (uint256 wethAmount, uint256 feeAmount) =
            adapter.calculateAmountToTransferWithYield(vaultIds.defaultVault, users.newDepositor, 100e18);

        assertEq(wethAmount, 0, "wethAmount");
        assertEq(feeAmount, 0, "feeAmount");
    }

    function test_CalculateAmountToTransferWithYield_GivenNotUnstaked() external view givenYieldTokenBalanceNotZero {
        // It should return zero.
        (uint256 wethAmount, uint256 feeAmount) =
            adapter.calculateAmountToTransferWithYield(vaultIds.vaultWithAdapter, users.depositor, DEPOSIT_AMOUNT);

        assertEq(wethAmount, 0, "wethAmount");
        assertEq(feeAmount, 0, "feeAmount");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SUPPORTS-INTERFACE
    //////////////////////////////////////////////////////////////////////////*/

    function test_SupportsInterface_WhenQueryingISablierBobAdapterInterface() external view {
        // It should return true.
        assertTrue(adapter.supportsInterface(type(ISablierBobAdapter).interfaceId), "ISablierBobAdapter");
    }

    function test_SupportsInterface_WhenQueryingISablierLidoAdapterInterface() external view {
        // It should return true.
        assertTrue(adapter.supportsInterface(type(ISablierLidoAdapter).interfaceId), "ISablierLidoAdapter");
    }

    function test_SupportsInterface_WhenQueryingIERC165Interface() external view {
        // It should return true.
        assertTrue(adapter.supportsInterface(0x01ffc9a7), "IERC165");
    }

    function test_SupportsInterface_WhenQueryingInvalidInterface() external view {
        // It should return false.
        assertFalse(adapter.supportsInterface(0xdeadbeef), "random");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  GET-VAULT-YIELD-FEE
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetVaultYieldFee_GivenNoFeeChangesAfterCreation() external view {
        // It should return the snapshotted fee.
        assertEq(adapter.getVaultYieldFee(vaultIds.vaultWithAdapter).unwrap(), YIELD_FEE.unwrap(), "vaultYieldFee");
    }

    function test_GetVaultYieldFee_GivenGlobalFeeChangedAfterCreation() external {
        uint256 initialVaultFee = adapter.getVaultYieldFee(vaultIds.vaultWithAdapter).unwrap();

        // Change the global yield fee.
        setMsgSender(address(comptroller));
        adapter.setYieldFee(MAX_YIELD_FEE);
        setMsgSender(users.newDepositor);

        // It should return the original snapshotted fee.
        assertEq(adapter.getVaultYieldFee(vaultIds.vaultWithAdapter).unwrap(), initialVaultFee, "vaultFee.unchanged");
        assertEq(adapter.feeOnYield().unwrap(), MAX_YIELD_FEE.unwrap(), "globalFee.changed");
    }
}
