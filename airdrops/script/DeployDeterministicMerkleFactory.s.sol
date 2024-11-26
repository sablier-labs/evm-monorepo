// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactory } from "../src/SablierMerkleFactory.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys Merkle factory contract at deterministic address.
///
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicMerkleFactory is BaseScript {
    /// @dev Deploy via Forge.
    function run(address initialAdmin) public virtual broadcast returns (SablierMerkleFactory merkleFactory) {
        merkleFactory = new SablierMerkleFactory{ salt: SALT }(initialAdmin);
    }
}
