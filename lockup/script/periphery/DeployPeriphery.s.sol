// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierBatchLockup } from "./../../src/periphery/SablierBatchLockup.sol";
import { SablierMerkleFactory } from "./../../src/periphery/SablierMerkleFactory.sol";
import { BaseScript } from "./../Base.s.sol";

/// @notice Deploys all Periphery contract in the following order:
///
/// 1. {SablierBatchLockup}
/// 2. {SablierMerkleFactory}
contract DeployPeriphery is BaseScript {
    /// @dev Deploy via Forge.
    function run(address initialAdmin)
        public
        virtual
        broadcast
        returns (SablierBatchLockup batchLockup, SablierMerkleFactory merkleFactory)
    {
        batchLockup = new SablierBatchLockup();
        merkleFactory = new SablierMerkleFactory(initialAdmin);
    }
}
