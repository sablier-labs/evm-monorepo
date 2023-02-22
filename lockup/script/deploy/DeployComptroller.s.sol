// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18 <0.9.0;

import { Script } from "forge-std/Script.sol";

import { SablierV2Comptroller } from "../../src/SablierV2Comptroller.sol";

import { BaseScript } from "../shared/Base.s.sol";

/// @notice Deploys the {SablierV2Comptroller} contract.
contract DeployComptroller is Script, BaseScript {
    function run(address initialAdmin) public virtual broadcaster returns (SablierV2Comptroller comptroller) {
        comptroller = new SablierV2Comptroller(initialAdmin);
    }
}
