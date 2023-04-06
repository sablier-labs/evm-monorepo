// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetDepositedAmount_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) { }

    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        lockup.getDepositedAmount(nullStreamId);
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return the correct deposited amount.
    function test_GetDepositedAmount() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        uint128 actualDepositedAmount = lockup.getDepositedAmount(streamId);
        uint128 expectedDepositedAmount = DEFAULT_DEPOSIT_AMOUNT;
        assertEq(actualDepositedAmount, expectedDepositedAmount, "depositedAmount");
    }
}
