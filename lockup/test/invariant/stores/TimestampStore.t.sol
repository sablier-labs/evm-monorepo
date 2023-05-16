// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup } from "src/types/DataTypes.sol";

/// @title TimestampStore
/// @dev Because Foundry does not commit the state changes between invariant runs, we need to
/// save the current timestamp in a handler with persistent storage.
contract TimestampStore {
    uint256 public currentTimestamp;

    constructor() {
        currentTimestamp = block.timestamp;
    }

    function increaseCurrentTimestamp(uint256 timeWarp) external {
        currentTimestamp += timeWarp;
    }
}
