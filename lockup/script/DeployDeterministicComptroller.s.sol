// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";

import { Common } from "./helpers/Common.s.sol";

/// @dev Deploys the {SablierV2Comptroller} contract at a deterministic address across all chains. Reverts if
/// the contract has already been deployed via the deterministic CREATE2 factory.
contract DeployDeterministicComptroller is Script, Common {
    /// @dev The presence of the salt instructs Forge to deploy the contract via a deterministic CREATE2 factory.
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(address initialAdmin) public virtual broadcaster returns (SablierV2Comptroller comptroller) {
        comptroller = new SablierV2Comptroller{ salt: ZERO_SALT }(initialAdmin);
    }
}
