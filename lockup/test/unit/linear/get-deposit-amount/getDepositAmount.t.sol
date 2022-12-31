// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { LinearTest } from "../LinearTest.t.sol";

contract GetDepositAmount__Test is LinearTest {
    /// @dev it should return zero.
    function testGetDepositAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualDepositAmount = linear.getDepositAmount(nonStreamId);
        uint128 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should the correct deposit amount.
    function testGetDepositAmount() external StreamExistent {
        uint256 defaultStreamId = createDefaultStream();
        uint128 actualDepositAmount = linear.getDepositAmount(defaultStreamId);
        uint128 expectedDepositAmount = defaultStream.amounts.deposit;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
