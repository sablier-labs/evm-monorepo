// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierV2BatchLockup } from "../../src/periphery/SablierV2BatchLockup.sol";

import { BaseScript } from "../Base.s.sol";

contract DeployBatchLockup is BaseScript {
    /// @dev Deploy via Forge.
    function run() public virtual broadcast returns (SablierV2BatchLockup batchLockup) {
        batchLockup = new SablierV2BatchLockup();
    }
}
