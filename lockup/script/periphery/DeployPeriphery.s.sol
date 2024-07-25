// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierV2MerkleLockupFactory } from "../../src/periphery/SablierV2MerkleLockupFactory.sol";
import { SablierV2BatchLockup } from "../../src/periphery/SablierV2BatchLockup.sol";

import { BaseScript } from "../Base.s.sol";

/// @notice Deploys all V2 Periphery contract in the following order:
///
/// 1. {SablierV2BatchLockup}
/// 2. {SablierV2MerkleLockupFactory}
contract DeployPeriphery is BaseScript {
    /// @dev Deploy via Forge.
    function run()
        public
        virtual
        broadcast
        returns (SablierV2BatchLockup batchLockup, SablierV2MerkleLockupFactory merkleLockupFactory)
    {
        batchLockup = new SablierV2BatchLockup();
        merkleLockupFactory = new SablierV2MerkleLockupFactory();
    }
}
