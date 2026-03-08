// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Enter_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Change caller to new depositor for this test.
        setMsgSender(users.newDepositor);
    }

    function test_RevertGiven_Null() external {
        // It should revert.
        expectRevert_Null(abi.encodeCall(bob.enter, (vaultIds.nullVault, DEPOSIT_AMOUNT)));
    }

    function test_RevertGiven_SETTLEDStatus() external givenNotNull {
        expectRevert_SETTLED(abi.encodeCall(bob.enter, (vaultIds.settledVault, DEPOSIT_AMOUNT)));
    }

    function test_RevertGiven_EXPIREDStatus() external givenNotNull {
        expectRevert_EXPIRED(abi.encodeCall(bob.enter, (vaultIds.defaultVault, DEPOSIT_AMOUNT)));
    }

    function test_RevertWhen_AmountZero() external givenNotNull givenACTIVEStatus {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierBob_DepositAmountZero.selector, vaultIds.defaultVault, users.newDepositor
            )
        );
        bob.enter(vaultIds.defaultVault, 0);
    }

    function test_RevertWhen_NewStatusEXPIRED()
        external
        givenNotNull
        givenACTIVEStatus
        whenAmountNotZero
        whenSyncChangesStatus
    {
        expectRevert_EXPIRED(abi.encodeCall(bob.enter, (vaultIds.defaultVault, DEPOSIT_AMOUNT)));
    }

    function test_RevertWhen_NewStatusSETTLED()
        external
        givenNotNull
        givenACTIVEStatus
        whenAmountNotZero
        whenSyncChangesStatus
    {
        // Set oracle price to target price so that the sync settles the vault.
        oracle.setPrice(TARGET_PRICE);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_VaultNotActive.selector, vaultIds.defaultVault));
        bob.enter(vaultIds.defaultVault, DEPOSIT_AMOUNT);
    }

    function test_GivenNoAdapter() external givenNotNull givenACTIVEStatus whenAmountNotZero whenSyncNotChangeStatus {
        uint256 shareBalanceBefore = defaultShareToken.balanceOf(users.newDepositor);

        // It should emit an {Enter} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Enter({
            vaultId: vaultIds.defaultVault,
            user: users.newDepositor,
            amountReceived: DEPOSIT_AMOUNT,
            sharesMinted: DEPOSIT_AMOUNT
        });

        // It should transfer tokens to the contract.
        expectCallToTransferFrom({ token: weth, from: users.newDepositor, to: address(bob), value: DEPOSIT_AMOUNT });

        bob.enter(vaultIds.defaultVault, DEPOSIT_AMOUNT);

        // It should mint share tokens to the caller.
        uint256 actualSharesMinted = defaultShareToken.balanceOf(users.newDepositor) - shareBalanceBefore;
        uint256 expectedSharesMinted = DEPOSIT_AMOUNT;
        assertEq(actualSharesMinted, expectedSharesMinted, "sharesMinted");
    }

    function test_GivenAdapter() external givenNotNull givenACTIVEStatus whenAmountNotZero whenSyncNotChangeStatus {
        // Get address of the share token for the vault with adapter.
        IBobVaultShare shareTokenForVaultWithAdapter = bob.getShareToken(vaultIds.vaultWithAdapter);
        uint256 shareBalanceBefore = shareTokenForVaultWithAdapter.balanceOf(users.newDepositor);
        uint256 wstETHBalanceBefore = wstEth.balanceOf(address(adapter));

        // It should emit {Enter} and {Stake} events.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.Stake({
            vaultId: vaultIds.vaultWithAdapter,
            user: users.newDepositor,
            depositAmount: DEPOSIT_AMOUNT,
            wrappedStakedAmount: WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT
        });

        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Enter({
            vaultId: vaultIds.vaultWithAdapter,
            user: users.newDepositor,
            amountReceived: DEPOSIT_AMOUNT,
            sharesMinted: DEPOSIT_AMOUNT
        });

        // It should transfer tokens to the adapter.
        expectCallToTransferFrom({ token: weth, from: users.newDepositor, to: address(adapter), value: DEPOSIT_AMOUNT });

        bob.enter(vaultIds.vaultWithAdapter, DEPOSIT_AMOUNT);

        // It should mint share tokens to the caller.
        uint256 actualSharesMinted = shareTokenForVaultWithAdapter.balanceOf(users.newDepositor) - shareBalanceBefore;
        uint256 expectedSharesMinted = DEPOSIT_AMOUNT;
        assertEq(actualSharesMinted, expectedSharesMinted, "sharesMinted");

        // It should stake via the adapter.
        uint256 actualWstETH = adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.newDepositor);
        uint256 expectedWstETH = WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT;
        assertEq(actualWstETH, expectedWstETH, "userWstETH");

        // It should update wstETH balance of the adapter.
        uint256 actualAdapterWstETHBalance = wstEth.balanceOf(address(adapter));
        uint256 expectedAdapterWstETHBalance = wstETHBalanceBefore + WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT;
        assertEq(actualAdapterWstETHBalance, expectedAdapterWstETHBalance, "adapterWstETHBalance");

        // It should update wstETH balance of the vault.
        uint256 actualWstETHBalanceForVault = adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter);
        uint256 expectedWstETHBalanceForVault = wstETHBalanceBefore + WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT;
        assertEq(actualWstETHBalanceForVault, expectedWstETHBalanceForVault, "wstETHBalanceForVault");
    }
}
