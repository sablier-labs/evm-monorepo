// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "../../src/interfaces/ISablierV2Comptroller.sol";
import { SablierV2LockupLinear } from "../../src/SablierV2LockupLinear.sol";

import { BaseScript } from "../shared/Base.s.sol";

/// @dev Deploys the {SablierV2LockupLinear} contract at a deterministic address across all chains. Reverts if
/// the contract has already been deployed.
contract DeployDeterministicLockupLinear is Script, BaseScript {
    /// @dev The presence of the salt instructs Forge to deploy the contract via a deterministic CREATE2 factory.
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        UD60x18 maxFee
    ) public virtual broadcaster returns (SablierV2LockupLinear linear) {
        linear = new SablierV2LockupLinear{ salt: ZERO_SALT }(initialAdmin, initialComptroller, maxFee);
    }
}
