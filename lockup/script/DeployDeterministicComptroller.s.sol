// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierV2Comptroller } from "../src/SablierV2Comptroller.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys {SablierV2Comptroller} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicComptroller is BaseScript {
    function run(address initialAdmin) public virtual broadcast returns (SablierV2Comptroller comptroller) {
        bytes32 salt = constructCreate2Salt();
        comptroller = new SablierV2Comptroller{ salt: salt }(initialAdmin);
    }
}
