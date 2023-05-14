// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Dynamic_Shared_Test } from "../Dynamic.t.sol";

contract CreateWithDeltas_Dynamic_Shared_Test is Dynamic_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        streamId = dynamic.nextStreamId();
    }

    modifier whenNoDelegateCall() {
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
