// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

contract GetYieldBearingTokenBalanceFor_Integration_Concrete_Test is Integration_Test {
    function test_GivenUserHasNoDeposits() external view {
        // It should return zero.
        assertEq(
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.newDepositor),
            0,
            "yieldBearingTokenBalance"
        );
    }

    function test_GivenUserHasDepositsViaAdapter() external view {
        // It should return the user wstETH balance.
        assertEq(
            adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.depositor),
            WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            "yieldBearingTokenBalance"
        );
    }
}
