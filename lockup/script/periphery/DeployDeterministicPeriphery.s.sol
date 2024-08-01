// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierBatchLockup } from "../../src/periphery/SablierBatchLockup.sol";
import { SablierMerkleLockupFactory } from "../../src/periphery/SablierMerkleLockupFactory.sol";

import { BaseScript } from "../Base.s.sol";

/// @notice Deploys all Periphery contracts at deterministic addresses across chains, in the following order:
///
/// 1. {SablierBatchLockup}
/// 2. {SablierMerkleLockupFactory}
///
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicPeriphery is BaseScript {
    /// @dev Deploy via Forge.
    function run()
        public
        virtual
        broadcast
        returns (SablierBatchLockup batchLockup, SablierMerkleLockupFactory merkleLockupFactory)
    {
        bytes32 salt = constructCreate2Salt();
        batchLockup = new SablierBatchLockup{ salt: salt }();
        merkleLockupFactory = new SablierMerkleLockupFactory{ salt: salt }();
    }
}
