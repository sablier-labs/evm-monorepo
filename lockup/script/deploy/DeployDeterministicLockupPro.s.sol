// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "../../src/interfaces/ISablierV2Comptroller.sol";
import { SablierV2LockupPro } from "../../src/SablierV2LockupPro.sol";

import { BaseScript } from "../shared/Base.s.sol";

/// @dev Deploys the {SablierV2LockupPro} contract at a deterministic address across all chains. Reverts if
/// the contract has already been deployed.
contract DeployDeterministicLockupPro is Script, BaseScript {
    /// @dev The presence of the salt instructs Forge to deploy the contract via a deterministic CREATE2 factory.
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) public virtual broadcaster returns (SablierV2LockupPro pro) {
        pro = new SablierV2LockupPro{ salt: ZERO_SALT }(initialAdmin, initialComptroller, maxFee, maxSegmentCount);
    }
}
