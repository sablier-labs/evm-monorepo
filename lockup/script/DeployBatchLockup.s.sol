// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierBatchLockup } from "../src/SablierBatchLockup.sol";

import { MaxCountScript } from "./MaxCount.s.sol";

contract DeployBatchLockup is MaxCountScript {
    /// @dev Deploy via Forge.
    function run() public broadcast returns (SablierBatchLockup batchLockup) {
        batchLockup = new SablierBatchLockup();
    }
}
