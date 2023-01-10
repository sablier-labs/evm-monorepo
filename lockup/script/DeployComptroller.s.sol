// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";

import { Common } from "./helpers/Common.s.sol";

/// @notice Deploys the SablierV2Comptroller contract from precompiled source (build optimized with --via-ir).
contract DeployComptroller is Script, Common {
    function run() public broadcaster returns (ISablierV2Comptroller comptroller) {
        comptroller = ISablierV2Comptroller(
            deployCode("optimized-out/SablierV2Comptroller.sol/SablierV2Comptroller.json")
        );
    }
}
