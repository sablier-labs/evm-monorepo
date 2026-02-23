// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Adapter_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
        setMsgSender(users.bob);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            ONLY_SABLIER_BOB MODIFIER
    //////////////////////////////////////////////////////////////////////////*/

    function test_RevertWhen_StakeCalledDirectly() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.bob, address(bob))
        );
        adapter.stake(1, users.bob, 1 ether);
    }

    function test_RevertWhen_UnstakeForUserWithinGracePeriodCalledDirectly() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.bob, address(bob))
        );
        adapter.unstakeForUserWithinGracePeriod(1, users.bob);
    }

    function test_RevertWhen_UnstakeAllCalledDirectly() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.bob, address(bob))
        );
        adapter.unstakeFullAmount(1);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CALCULATE REDEMPTION
    //////////////////////////////////////////////////////////////////////////*/

    function test_CalculateRedemption_NoWstETH() external view {
        uint256 vaultId = vaultIds.defaultVault;
        (uint256 wethAmount, uint256 feeAmount) = adapter.calculateAmountToTransferWithYield(vaultId, users.bob, 100e18);

        assertEq(wethAmount, 0, "wethAmount");
        assertEq(feeAmount, 0, "feeAmount");
    }

    function test_CalculateRedemption_BeforeUnstake() external view {
        (uint256 wethAmount, uint256 feeAmount) =
            adapter.calculateAmountToTransferWithYield(vaultIds.vaultWithAdapter, users.depositor, DEPOSIT_AMOUNT);

        assertEq(wethAmount, 0, "wethAmount");
        assertEq(feeAmount, 0, "feeAmount");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ERC165 INTERFACE
    //////////////////////////////////////////////////////////////////////////*/

    function test_SupportsInterface_ISablierBobAdapter() external view {
        assertTrue(adapter.supportsInterface(type(ISablierBobAdapter).interfaceId), "ISablierBobAdapter");
    }

    function test_SupportsInterface_ISablierLidoAdapter() external view {
        assertTrue(adapter.supportsInterface(type(ISablierLidoAdapter).interfaceId), "ISablierLidoAdapter");
    }

    function test_SupportsInterface_IERC165() external view {
        assertTrue(adapter.supportsInterface(0x01ffc9a7), "IERC165");
    }

    function test_SupportsInterface_InvalidInterface() external view {
        assertFalse(adapter.supportsInterface(0xdeadbeef), "random");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   GET VAULT YIELD FEE
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetVaultYieldFee_ReturnsSnapshotedFee() external view {
        assertEq(adapter.getVaultYieldFee(vaultIds.vaultWithAdapter).unwrap(), YIELD_FEE.unwrap(), "vaultYieldFee");
    }

    function test_GetVaultYieldFee_ImmutableAfterCreation() external {
        uint256 initialVaultFee = adapter.getVaultYieldFee(vaultIds.vaultWithAdapter).unwrap();

        setMsgSender(address(comptroller));
        adapter.setYieldFee(MAX_YIELD_FEE);
        setMsgSender(users.bob);

        assertEq(adapter.getVaultYieldFee(vaultIds.vaultWithAdapter).unwrap(), initialVaultFee, "vaultFee.unchanged");
        assertEq(adapter.feeOnYield().unwrap(), MAX_YIELD_FEE.unwrap(), "globalFee.changed");
    }
}
