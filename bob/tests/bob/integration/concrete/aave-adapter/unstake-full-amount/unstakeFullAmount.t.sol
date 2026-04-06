// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IAavePool } from "src/interfaces/external/IAavePool.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract UnstakeFullAmount_AaveAdapter_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierAaveAdapter_OnlySablierBob.selector, users.depositor, address(bob))
        );
        aaveAdapter.unstakeFullAmount(vaultIds.vaultWithAaveAdapter);
    }

    function test_WhenCallerBob() external whenCallerBob {
        // It should withdraw tokens from Aave to SablierBob.
        vm.expectCall({
            callee: address(aavePool),
            data: abi.encodeCall(IAavePool.withdraw, (address(wbtc), WBTC_DEPOSIT_AMOUNT, address(bob)))
        });

        // It should emit an {UnstakeFullAmount} event.
        vm.expectEmit({ emitter: address(aaveAdapter) });
        emit ISablierBobAdapter.UnstakeFullAmount({
            vaultId: vaultIds.vaultWithAaveAdapter,
            totalStakedAmount: WBTC_DEPOSIT_AMOUNT,
            amountReceivedFromUnstaking: WBTC_DEPOSIT_AMOUNT
        });

        (uint128 totalVaultATokenBalance, uint128 amountReceivedFromUnstaking) =
            aaveAdapter.unstakeFullAmount(vaultIds.vaultWithAaveAdapter);

        // It should return the correct total aToken balance.
        assertEq(totalVaultATokenBalance, WBTC_DEPOSIT_AMOUNT, "totalVaultATokenBalance");

        // It should return the correct amount received from unstaking.
        assertEq(amountReceivedFromUnstaking, WBTC_DEPOSIT_AMOUNT, "amountReceivedFromUnstaking");

        // It should store the tokens received after unstaking.
        assertEq(
            aaveAdapter.getTokensReceivedAfterUnstaking(vaultIds.vaultWithAaveAdapter),
            WBTC_DEPOSIT_AMOUNT,
            "tokensReceivedAfterUnstaking"
        );
    }
}
