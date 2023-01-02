// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract GetDepositAmount__Test is SharedTest {
    /// @dev it should return zero.
    function testGetDepositAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualDepositAmount = sablierV2.getDepositAmount(nonStreamId);
        uint128 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct deposit amount.
    function testGetDepositAmount() external StreamExistent {
        uint256 defaultStreamId = createDefaultStream();
        uint128 actualDepositAmount = sablierV2.getDepositAmount(defaultStreamId);
        uint128 expectedDepositAmount = DEFAULT_NET_DEPOSIT_AMOUNT;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
