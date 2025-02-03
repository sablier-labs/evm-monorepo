// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierBatchLockup } from "../src/SablierBatchLockup.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployDeterministicBatchLockup is BaseScript {
    /// @dev Deploy via Forge.
    function run() public broadcast returns (SablierBatchLockup batchLockup) {
        batchLockup = new SablierBatchLockup{ salt: SALT }();
    }
}
