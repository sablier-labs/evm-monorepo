// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { LockupTranched_Integration_Shared_Test } from "./LockupTranched.t.sol";

contract CreateWithDurations_Integration_Shared_Test is LockupTranched_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        streamId = lockupTranched.nextStreamId();
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    modifier whenLoopCalculationsDoNotOverflowBlockGasLimit() {
        _;
    }

    modifier whenDurationsNotZero() {
        _;
    }

    modifier whenTimestampsCalculationsDoNotOverflow() {
        _;
    }
}
