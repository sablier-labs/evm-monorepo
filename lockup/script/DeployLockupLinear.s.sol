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
        address admin,
        ISablierV2Comptroller comptroller,
        UD60x18 maxFee
    ) public broadcaster returns (SablierV2LockupLinear linear) {
        linear = new SablierV2LockupLinear({ initialAdmin: admin, initialComptroller: comptroller, maxFee: maxFee });
    }
}
