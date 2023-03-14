// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "../../src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2NFTDescriptor } from "../../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2LockupLinear } from "../../src/SablierV2LockupLinear.sol";

import { BaseScript } from "../shared/Base.s.sol";

/// @notice Deploys the {SablierV2LockupLinear} contract.
contract DeployLockupLinear is Script, BaseScript {
    function run(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        ISablierV2NFTDescriptor initialNFTDescriptor,
        UD60x18 maxFee
    ) public virtual broadcaster returns (SablierV2LockupLinear linear) {
        linear = new SablierV2LockupLinear(initialAdmin, initialComptroller, initialNFTDescriptor, maxFee);
    }
}
