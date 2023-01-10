// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Linear } from "src/interfaces/ISablierV2Linear.sol";

import { Common } from "./helpers/Common.s.sol";

/// @notice Deploys the SablierV2Linear contract from precompiled source (build optimized with --via-ir).
contract DeployLinear is Script, Common {
    function run(
        ISablierV2Comptroller comptroller,
        UD60x18 maxFee
    ) public broadcaster returns (ISablierV2Linear linear) {
        linear = ISablierV2Linear(
            deployCode("optimized-out/SablierV2Linear.sol/SablierV2Linear.json", abi.encode(comptroller, maxFee))
        );
    }
}
