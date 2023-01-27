// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetDepositAmount_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {}

    /// @dev it should return zero.
    function test_GetDepositAmount_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint128 actualDepositAmount = lockup.getDepositAmount(nullStreamId);
        uint128 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount, "depositAmount");
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct deposit amount.
    function test_GetDepositAmount() external streamNonNull {
        uint256 streamId = createDefaultStream();
        uint128 actualDepositAmount = lockup.getDepositAmount(streamId);
        uint128 expectedDepositAmount = DEFAULT_NET_DEPOSIT_AMOUNT;
        assertEq(actualDepositAmount, expectedDepositAmount, "depositAmount");
    }
}
