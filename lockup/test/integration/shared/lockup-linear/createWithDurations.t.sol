// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupLinear_Integration_Shared_Test } from "./LockupLinear.t.sol";

contract CreateWithDurations_Integration_Shared_Test is LockupLinear_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        streamId = lockupLinear.nextStreamId();
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
