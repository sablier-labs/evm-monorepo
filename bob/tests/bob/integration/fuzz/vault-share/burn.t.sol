// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierBob } from "src/interfaces/ISablierBob.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Burn_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_Burn(uint128 amount) external whenCallerBob {
        amount = boundUint128(amount, 1, DEPOSIT_AMOUNT);

        uint256 balanceBefore = defaultShareToken.balanceOf(users.depositor);

        vm.expectCall(address(bob), abi.encodeWithSelector(ISablierBob.onShareTransfer.selector), 0);

        defaultShareToken.burn(vaultIds.defaultVault, users.depositor, amount);

        // It should decrease the balance.
        uint256 actualBalance = defaultShareToken.balanceOf(users.depositor);
        uint256 expectedBalance = balanceBefore - amount;
        assertEq(actualBalance, expectedBalance, "balance");
    }
}
