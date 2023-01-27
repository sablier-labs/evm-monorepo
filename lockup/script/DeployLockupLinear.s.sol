// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";

import { Common } from "./helpers/Common.s.sol";

/// @notice Deploys the {SablierV2LockupLinear} contract.
contract DeployLockupLinear is Script, Common {
    function run(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        UD60x18 maxFee
    ) public virtual broadcaster returns (SablierV2LockupLinear linear) {
        linear = new SablierV2LockupLinear(initialAdmin, initialComptroller, maxFee);
    }
}
