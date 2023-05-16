// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";

import { LockupStore } from "../stores/LockupStore.sol";
import { TimestampStore } from "../stores/TimestampStore.sol";
import { LockupHandler } from "./LockupHandler.sol";

/// @title LockupLinearHandler
/// @dev This contract and not {SablierV2LockupLinear} is exposed to Foundry for invariant testing. The point is
/// to bound and restrict the inputs that get passed to the real-world contract to avoid getting reverts.
contract LockupLinearHandler is LockupHandler {
    constructor(
        TimestampStore timestampStore_,
        LockupStore lockupStore_,
        IERC20 asset_,
        ISablierV2LockupLinear linear_
    )
        LockupHandler(timestampStore_, lockupStore_, asset_, linear_)
    { }
}
