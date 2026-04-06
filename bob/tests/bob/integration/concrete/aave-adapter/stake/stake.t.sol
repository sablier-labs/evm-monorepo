// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IAavePool } from "src/interfaces/external/IAavePool.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Stake_AaveAdapter_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Since this test is from Bob's perspective, we need to transfer WBTC to the adapter before calling `stake`.
        wbtc.transfer(address(aaveAdapter), WBTC_DEPOSIT_AMOUNT);
    }

    function test_RevertWhen_CallerNotBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierAaveAdapter_OnlySablierBob.selector, users.depositor, address(bob))
        );
        aaveAdapter.stake(vaultIds.vaultWithAaveAdapter, users.newDepositor, WBTC_DEPOSIT_AMOUNT);
    }

    function test_WhenCallerBob() external {
        // It should supply tokens to Aave Pool.
        vm.expectCall({
            callee: address(aavePool),
            data: abi.encodeCall(IAavePool.supply, (address(wbtc), WBTC_DEPOSIT_AMOUNT, address(aaveAdapter), 0))
        });

        // It should emit a {Stake} event.
        vm.expectEmit({ emitter: address(aaveAdapter) });
        emit ISablierBobAdapter.Stake({
            vaultId: vaultIds.vaultWithAaveAdapter,
            user: users.newDepositor,
            depositAmount: WBTC_DEPOSIT_AMOUNT,
            wrappedStakedAmount: WBTC_DEPOSIT_AMOUNT // At normalizedIncome = 1e27, scaled = actual.
        });

        // Change caller to Bob.
        setMsgSender(address(bob));
        aaveAdapter.stake(vaultIds.vaultWithAaveAdapter, users.newDepositor, WBTC_DEPOSIT_AMOUNT);

        // It should update vault total scaled balance.
        uint256 actualVaultTotal = aaveAdapter.getATokenTotalScaledBalance(vaultIds.vaultWithAaveAdapter);
        uint256 expectedVaultTotal = 2 * WBTC_DEPOSIT_AMOUNT; // One from setUp, one from this stake.
        assertEq(actualVaultTotal, expectedVaultTotal, "vaultTotalScaledBalance");

        // It should update user scaled balance.
        uint256 actualUserScaled =
            aaveAdapter.getATokenUserScaledBalance(vaultIds.vaultWithAaveAdapter, users.newDepositor);
        uint256 expectedUserScaled = WBTC_DEPOSIT_AMOUNT;
        assertEq(actualUserScaled, expectedUserScaled, "userScaledBalance");
    }
}
