// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ProTest } from "../ProTest.t.sol";

contract GetDepositAmount__Test is ProTest {
    /// @dev it should return zero.
    function testGetDepositAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualDepositAmount = pro.getDepositAmount(nonStreamId);
        uint128 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should the correct deposit amount.
    function testGetDepositAmount() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        uint128 actualDepositAmount = pro.getDepositAmount(daiStreamId);
        uint128 expectedDepositAmount = daiStream.depositAmount;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
