// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Enter_Integration_Concrete_Test is Integration_Test {
    /// @dev The share token for the default vault.
    IERC20 internal shareToken;

    function setUp() public override {
        Integration_Test.setUp();

        // Change called to bob for this test.
        setMsgSender(users.bob);

        // Get the share token for the default vault.
        shareToken = bob.getShareToken(vaultIds.defaultVault);
    }

    function test_RevertGiven_Null() external {
        // It should revert.
        expectRevert_Null(abi.encodeCall(bob.enter, (vaultIds.nullVault, DEPOSIT_AMOUNT)));
    }

    function test_RevertGiven_SETTLED() external givenNotNull {
        expectRevert_SETTLED(abi.encodeCall(bob.enter, (vaultIds.settledVault, DEPOSIT_AMOUNT)));
    }

    function test_RevertGiven_EXPIRED() external givenNotNull {
        expectRevert_EXPIRED(abi.encodeCall(bob.enter, (vaultIds.defaultVault, DEPOSIT_AMOUNT)));
    }

    function test_RevertWhen_AmountZero() external givenNotNull givenACTIVE {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_DepositAmountZero.selector, vaultIds.defaultVault, users.bob)
        );
        bob.enter(vaultIds.defaultVault, 0);
    }

    function test_WhenFirstDeposit() external givenNotNull givenACTIVE whenAmountNotZero givenNoAdapter {
        uint256 shareBalanceBefore = shareToken.balanceOf(users.bob);

        // It should emit an {Enter} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Enter({
            vaultId: vaultIds.defaultVault,
            user: users.bob,
            amountReceived: DEPOSIT_AMOUNT,
            sharesMinted: DEPOSIT_AMOUNT
        });

        // It should transfer tokens to the contract.
        expectCallToTransferFrom({ token: weth, from: users.bob, to: address(bob), value: DEPOSIT_AMOUNT });

        bob.enter(vaultIds.defaultVault, DEPOSIT_AMOUNT);

        // It should mint share tokens to the caller.
        uint256 actualSharesMinted = shareToken.balanceOf(users.bob) - shareBalanceBefore;
        uint256 expectedSharesMinted = DEPOSIT_AMOUNT;
        assertEq(actualSharesMinted, expectedSharesMinted, "sharesMinted");

        // It should set the first deposit time.
        uint40 actualFirstDepositTime = bob.getFirstDepositTime(vaultIds.defaultVault, users.bob);
        uint40 expectedFirstDepositTime = getBlockTimestamp();
        assertEq(actualFirstDepositTime, expectedFirstDepositTime, "firstDepositTime");
    }

    function test_WhenNotFirstDeposit() external givenNotNull givenACTIVE whenAmountNotZero givenNoAdapter {
        // Deposit into vault so that the first deposit time is set.
        bob.enter(vaultIds.defaultVault, DEPOSIT_AMOUNT);
        uint40 firstDepositedAt = getBlockTimestamp();

        // Warp to 1 hour later.
        vm.warp(getBlockTimestamp() + 1 hours);

        uint256 shareBalanceBefore = shareToken.balanceOf(users.bob);

        // It should emit an {Enter} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Enter({
            vaultId: vaultIds.defaultVault,
            user: users.bob,
            amountReceived: DEPOSIT_AMOUNT,
            sharesMinted: DEPOSIT_AMOUNT
        });

        // It should transfer tokens to the contract.
        expectCallToTransferFrom({ token: weth, from: users.bob, to: address(bob), value: DEPOSIT_AMOUNT });

        bob.enter(vaultIds.defaultVault, DEPOSIT_AMOUNT);

        // It should mint share tokens to the caller.
        uint256 actualSharesMinted = shareToken.balanceOf(users.bob) - shareBalanceBefore;
        uint256 expectedSharesMinted = DEPOSIT_AMOUNT;
        assertEq(actualSharesMinted, expectedSharesMinted, "sharesMinted");

        // It should not update the first deposit time.
        uint40 actualFirstDepositTime = bob.getFirstDepositTime(vaultIds.defaultVault, users.bob);
        uint40 expectedFirstDepositTime = firstDepositedAt;
        assertEq(actualFirstDepositTime, expectedFirstDepositTime, "firstDepositTime");
    }

    function test_GivenAdapter() external givenNotNull givenACTIVE whenAmountNotZero {
        // Get address of the share token for the vault with adapter.
        shareToken = bob.getShareToken(vaultIds.vaultWithAdapter);
        uint256 shareBalanceBefore = shareToken.balanceOf(users.bob);
        uint256 wstETHBalanceBefore = wstEth.balanceOf(address(adapter));

        // It should emit an {Enter} and {Stake} events.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.Stake({
            vaultId: vaultIds.vaultWithAdapter,
            user: users.bob,
            depositAmount: DEPOSIT_AMOUNT,
            wrappedStakedAmount: WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT
        });

        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Enter({
            vaultId: vaultIds.vaultWithAdapter,
            user: users.bob,
            amountReceived: DEPOSIT_AMOUNT,
            sharesMinted: DEPOSIT_AMOUNT
        });

        // It should transfer tokens to the adapter.
        expectCallToTransferFrom({ token: weth, from: users.bob, to: address(adapter), value: DEPOSIT_AMOUNT });

        bob.enter(vaultIds.vaultWithAdapter, DEPOSIT_AMOUNT);

        // It should mint share tokens to the caller.
        uint256 actualSharesMinted = shareToken.balanceOf(users.bob) - shareBalanceBefore;
        uint256 expectedSharesMinted = DEPOSIT_AMOUNT;
        assertEq(actualSharesMinted, expectedSharesMinted, "sharesMinted");

        // It should set the first deposit time.
        uint40 actualFirstDepositTime = bob.getFirstDepositTime(vaultIds.vaultWithAdapter, users.bob);
        uint40 expectedFirstDepositTime = getBlockTimestamp();
        assertEq(actualFirstDepositTime, expectedFirstDepositTime, "firstDepositTime");

        // It should stake via the adapter.
        uint256 actualWstETH = adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.bob);
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
