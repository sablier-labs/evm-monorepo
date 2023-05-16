// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2LockupDynamic } from "src/interfaces/ISablierV2LockupDynamic.sol";

import { LockupStore } from "../stores/LockupStore.t.sol";
import { TimestampStore } from "../stores/TimestampStore.t.sol";
import { LockupHandler } from "./LockupHandler.t.sol";

/// @title LockupDynamicHandler
/// @dev This contract and not {SablierV2LockupDynamic} is exposed to Foundry for invariant testing. The point is
/// to bound and restrict the inputs that get passed to the real-world contract to avoid getting reverts.
contract LockupDynamicHandler is LockupHandler {
    constructor(
        TimestampStore timestampStore_,
        LockupStore lockupStore_,
        IERC20 asset_,
        ISablierV2LockupDynamic dynamic_
    )
        LockupHandler(timestampStore_, lockupStore_, asset_, dynamic_)
    { }
}
