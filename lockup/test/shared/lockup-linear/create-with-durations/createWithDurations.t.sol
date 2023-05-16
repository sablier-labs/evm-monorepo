// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Linear_Shared_Test } from "../Linear.t.sol";

contract CreateWithDurations_Linear_Shared_Test is Linear_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        streamId = linear.nextStreamId();
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    modifier whenCliffDurationCalculationDoesNotOverflow() {
        _;
    }

    modifier whenTotalDurationCalculationDoesNotOverflow() {
        _;
    }
}
