// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract GetDepositAmount_Test is SharedTest {
    /// @dev it should return zero.
    function test_GetDepositAmount_StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualDepositAmount = sablierV2.getDepositAmount(nonStreamId);
        uint128 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct deposit amount.
    function test_GetDepositAmount() external StreamExistent {
        uint256 streamId = createDefaultStream();
        uint128 actualDepositAmount = sablierV2.getDepositAmount(streamId);
        uint128 expectedDepositAmount = DEFAULT_NET_DEPOSIT_AMOUNT;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
