// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Linear } from "src/interfaces/ISablierV2Linear.sol";
import { ISablierV2Pro } from "src/interfaces/ISablierV2Pro.sol";

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
    ) public broadcaster returns (ISablierV2Comptroller comptroller, ISablierV2Linear linear, ISablierV2Pro pro) {
        comptroller = ISablierV2Comptroller(
            deployCode("optimized-out/SablierV2Comptroller.sol/SablierV2Comptroller.json")
        );

        linear = ISablierV2Linear(
            deployCode("optimized-out/SablierV2Linear.sol/SablierV2Linear.json", abi.encode(comptroller, maxFee))
        );

        pro = ISablierV2Pro(
            deployCode(
                "optimized-out/SablierV2Pro.sol/SablierV2Pro.json",
                abi.encode(comptroller, maxFee, maxSegmentCount)
            )
        );
    }
}
