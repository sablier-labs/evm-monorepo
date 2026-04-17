// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierBob } from "src/interfaces/ISablierBob.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Mint_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_Mint(uint128 amount) external whenCallerBob {
        amount = boundUint128(amount, 1, MAX_UINT128);

        uint256 balanceBefore = defaultShareToken.balanceOf(users.depositor);

        vm.expectCall(address(bob), abi.encodeWithSelector(ISablierBob.onShareTransfer.selector), 0);

        defaultShareToken.mint(vaultIds.defaultVault, users.depositor, amount);

        // It should increase the balance.
        uint256 actualBalance = defaultShareToken.balanceOf(users.depositor);
        uint256 expectedBalance = balanceBefore + amount;
        assertEq(actualBalance, expectedBalance, "balance");
    }
}
