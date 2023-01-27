// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";

import { Common } from "./helpers/Common.s.sol";

/// @notice Deploys the {SablierV2Comptroller} contract.
contract DeployComptroller is Script, Common {
    function run(address initialAdmin) public broadcaster returns (SablierV2Comptroller comptroller) {
        comptroller = new SablierV2Comptroller(initialAdmin);
    }
}
