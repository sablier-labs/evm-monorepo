// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierBatchLockup } from "../../src/periphery/SablierBatchLockup.sol";
import { SablierMerkleFactory } from "../../src/periphery/SablierMerkleFactory.sol";

import { BaseScript } from "../Base.s.sol";

/// @notice Deploys all Periphery contracts at deterministic addresses across chains, in the following order:
///
/// 1. {SablierBatchLockup}
/// 2. {SablierMerkleFactory}
///
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicPeriphery is BaseScript {
    /// @dev Deploy via Forge.
    function run(address initialAdmin)
        public
        virtual
        broadcast
        returns (SablierBatchLockup batchLockup, SablierMerkleFactory merkleFactory)
    {
        bytes32 salt = constructCreate2Salt();
        batchLockup = new SablierBatchLockup{ salt: salt }();
        merkleFactory = new SablierMerkleFactory{ salt: salt }(initialAdmin);
    }
}
