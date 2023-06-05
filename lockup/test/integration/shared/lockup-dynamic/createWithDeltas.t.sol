// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupDynamic_Integration_Shared_Test } from "./LockupDynamic.t.sol";

contract CreateWithDeltas_Integration_Shared_Test is LockupDynamic_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        streamId = lockupDynamic.nextStreamId();
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    modifier whenLoopCalculationsDoNotOverflowBlockGasLimit() {
        _;
    }

    modifier whenDeltasNotZero() {
        _;
    }

    modifier whenMilestonesCalculationsDoNotOverflow() {
        _;
    }
}
