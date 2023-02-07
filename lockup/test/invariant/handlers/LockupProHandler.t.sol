// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2LockupPro } from "src/interfaces/ISablierV2LockupPro.sol";

import { LockupHandler } from "./LockupHandler.t.sol";
import { LockupHandlerStorage } from "./LockupHandlerStorage.t.sol";

/// @title LockupProHandler
/// @dev This contract and not {SablierV2LockupPro} is exposed to Foundry for invariant testing. The point is
/// to bound and restrict the inputs that get passed to the real-world contract to avoid getting reverts.
contract LockupProHandler is LockupHandler {
    constructor(
        IERC20 asset_,
        ISablierV2LockupPro pro_,
        LockupHandlerStorage store_
    ) LockupHandler(asset_, pro_, store_) {}
}
