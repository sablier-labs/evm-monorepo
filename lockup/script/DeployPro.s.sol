// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Pro } from "src/interfaces/ISablierV2Pro.sol";

import { Common } from "./helpers/Common.s.sol";

/// @notice Deploys the SablierV2Linear contract from precompiled source (build optimized with --via-ir).
contract DeployPro is Script, Common {
    function run(
        ISablierV2Comptroller comptroller,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) public broadcaster returns (ISablierV2Pro pro) {
        pro = ISablierV2Pro(
            deployCode(
                "optimized-out/SablierV2Pro.sol/SablierV2Pro.json",
                abi.encode(comptroller, maxFee, maxSegmentCount)
            )
        );
    }
}
