// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract ExitWithinGracePeriod_Integration_Concrete_Test is Integration_Test {
    /// @dev The share token for the default vault.
    IERC20 internal shareToken;

    function setUp() public override {
        Integration_Test.setUp();

        shareToken = bob.getShareToken(vaultIds.defaultVault);
    }

    function test_RevertGiven_Null() external {
        expectRevert_Null(abi.encodeCall(bob.exitWithinGracePeriod, (vaultIds.nullVault)));
    }

    function test_RevertGiven_SETTLED() external givenNotNull {
        expectRevert_SETTLED(abi.encodeCall(bob.exitWithinGracePeriod, (vaultIds.settledVault)));
    }

    function test_RevertGiven_EXPIRED() external givenNotNull {
        expectRevert_EXPIRED(abi.encodeCall(bob.exitWithinGracePeriod, (vaultIds.defaultVault)));
    }

    function test_RevertWhen_SharesZero() external givenNotNull givenACTIVE {
        // Transfer shares to bob so that depositor does not have shares.
        shareToken.transfer(users.bob, DEPOSIT_AMOUNT);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_NoSharesToRedeem.selector, vaultIds.defaultVault, users.depositor)
        );
        bob.exitWithinGracePeriod(vaultIds.defaultVault);
    }

    function test_RevertGiven_FirstDepositTimeZero() external givenNotNull givenACTIVE whenSharesNotZero {
        // Transfer shares to bob.
        shareToken.transfer(users.bob, DEPOSIT_AMOUNT);

        setMsgSender(users.bob);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_CallerNotDepositor.selector, vaultIds.defaultVault, users.bob)
        );
        bob.exitWithinGracePeriod(vaultIds.defaultVault);
    }

    function test_RevertWhen_GraceEndTimeNotInFuture()
        external
        givenNotNull
        givenACTIVE
        whenSharesNotZero
        givenFirstDepositTimeNotZero
    {
        uint40 gracePeriodEndAt = FEB_1_2026 + GRACE_PERIOD;

        vm.warp(gracePeriodEndAt + 1);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierBob_GracePeriodExpired.selector,
                vaultIds.defaultVault,
                users.depositor,
                FEB_1_2026,
                gracePeriodEndAt
            )
        );
        bob.exitWithinGracePeriod(vaultIds.defaultVault);
    }

    function test_GivenNoAdapter()
        external
        givenNotNull
        givenACTIVE
        whenSharesNotZero
        givenFirstDepositTimeNotZero
        whenGraceEndTimeInFuture
    {
        vm.warp(FEB_1_2026 + GRACE_PERIOD);

        _testExitWithinGracePeriod({ vaultId: vaultIds.defaultVault });
    }

    function test_GivenAdapter()
        external
        givenNotNull
        givenACTIVE
        whenSharesNotZero
        givenFirstDepositTimeNotZero
        whenGraceEndTimeInFuture
    {
        uint256 adapterWstETHBefore = wstEth.balanceOf(address(adapter));

        vm.warp(FEB_1_2026 + GRACE_PERIOD);

        // It should emit an {UnstakeForUserWithinGracePeriod} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.UnstakeForUserWithinGracePeriod({
            vaultId: vaultIds.vaultWithAdapter,
            user: users.depositor,
            wrappedStakedAmount: WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            withdrawnAmount: DEPOSIT_AMOUNT
        });

        _testExitWithinGracePeriod({ vaultId: vaultIds.vaultWithAdapter });

        // It should set user wstETH balance to 0.
        uint256 actualUserWstETHBalance =
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor);
        assertEq(actualUserWstETHBalance, 0, "userWstETH");

        // It should reduce adapter wstETH balance.
        uint256 actualAdapterWstETHBalance = wstEth.balanceOf(address(adapter));
        uint256 expectedAdapterWstETHBalance = adapterWstETHBefore - WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT;
        assertEq(actualAdapterWstETHBalance, expectedAdapterWstETHBalance, "adapterWstETHBalance");

        // It should update wstETH balance of the vault.
        uint256 actualWstETHBalanceForVault = adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter);
        uint256 expectedWstETHBalanceForVault = adapterWstETHBefore - WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT;
        assertEq(actualWstETHBalanceForVault, expectedWstETHBalanceForVault, "wstETHBalanceForVault");
    }

    /// @dev Shared logic for testing exitWithinGracePeriod.
    function _testExitWithinGracePeriod(uint256 vaultId) private {
        // It should emit an {ExitWithinGracePeriod} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.ExitWithinGracePeriod({
            vaultId: vaultId,
            user: users.depositor,
            amountReceived: DEPOSIT_AMOUNT,
            sharesBurned: DEPOSIT_AMOUNT
        });

        // It should return the deposit amount.
        expectCallToTransfer(weth, users.depositor, DEPOSIT_AMOUNT);

        bob.exitWithinGracePeriod(vaultId);

        // It should burn all shares.
        uint256 actualShareBalance = bob.getShareToken(vaultId).balanceOf(users.depositor);
        assertEq(actualShareBalance, 0, "shareBalance");

        // It should clear the first deposit time.
        assertEq(bob.getFirstDepositTime(vaultId, users.depositor), 0, "firstDepositTime");
    }
}
