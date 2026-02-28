// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

contract GetTotalYieldBearingTokenBalance_Integration_Concrete_Test is Integration_Test {
    function test_GivenVaultWithNoAdapterDeposits() external view {
        // It should return zero.
        assertEq(adapter.getTotalYieldBearingTokenBalance(vaultIds.defaultVault), 0, "totalYieldBearingTokenBalance");
    }

    function test_GivenVaultWithAdapterDeposits() external view {
        // It should return the total wstETH balance.
        assertEq(
            adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter),
            WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            "totalYieldBearingTokenBalance"
        );
    }
}
