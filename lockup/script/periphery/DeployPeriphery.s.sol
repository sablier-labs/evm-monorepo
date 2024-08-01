// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleLockupFactory } from "../../src/periphery/SablierMerkleLockupFactory.sol";
import { SablierBatchLockup } from "../../src/periphery/SablierBatchLockup.sol";

import { BaseScript } from "../Base.s.sol";

/// @notice Deploys all Periphery contract in the following order:
///
/// 1. {SablierBatchLockup}
/// 2. {SablierMerkleLockupFactory}
contract DeployPeriphery is BaseScript {
    /// @dev Deploy via Forge.
    function run()
        public
        virtual
        broadcast
        returns (SablierBatchLockup batchLockup, SablierMerkleLockupFactory merkleLockupFactory)
    {
        batchLockup = new SablierBatchLockup();
        merkleLockupFactory = new SablierMerkleLockupFactory();
    }
}
