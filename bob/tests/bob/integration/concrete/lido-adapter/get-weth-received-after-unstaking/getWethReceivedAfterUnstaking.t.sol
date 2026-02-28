// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

contract GetWethReceivedAfterUnstaking_Integration_Concrete_Test is Integration_Test {
    function test_GivenVaultNotUnstaked() external view {
        // It should return zero.
        assertEq(adapter.getWethReceivedAfterUnstaking(vaultIds.vaultWithAdapter), 0, "wethReceivedAfterUnstaking");
    }

    function test_GivenVaultUnstaked() external {
        // Warp past expiry so the vault can be unstaked.
        vm.warp(EXPIRY + 1);
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);

        // It should return the WETH received.
        uint256 wethReceived = adapter.getWethReceivedAfterUnstaking(vaultIds.vaultWithAdapter);
        assertGt(wethReceived, 0, "wethReceivedAfterUnstaking");
    }
}
