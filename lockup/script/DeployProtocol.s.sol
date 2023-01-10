// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2Linear } from "src/SablierV2Linear.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { Common } from "./helpers/Common.s.sol";
import { DeployComptroller } from "./DeployComptroller.s.sol";

/// @notice Deploys the entire Sablier V2 protocol from precompiled source (build optimized with --via-ir):
///
/// The contracts are deployed in the following order:
///
/// 1. SablierV2Comptroller
/// 2. SablierV2Linear
/// 3. SablierV2Pro
contract DeployProtocol is Script, Common {
    function run(
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) public broadcaster returns (SablierV2Comptroller comptroller, SablierV2Linear linear, SablierV2Pro pro) {
        comptroller = new SablierV2Comptroller();
        linear = new SablierV2Linear(comptroller, maxFee);
        pro = new SablierV2Pro(comptroller, maxFee, maxSegmentCount);
    }
}
