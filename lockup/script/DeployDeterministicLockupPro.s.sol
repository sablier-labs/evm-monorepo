// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { SablierV2LockupPro } from "src/SablierV2LockupPro.sol";

import { Common } from "./helpers/Common.s.sol";

/// @dev Deploys the {SablierV2LockupPro} contract at a deterministic address across all chains. Reverts if
/// the contract has already been deployed via the deterministic CREATE2 factory.
contract DeployDeterministicLockupPro is Script, Common {
    /// @dev The presence of the salt instructs Forge to deploy the contract via a deterministic CREATE2 factory.
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(
        address admin,
        ISablierV2Comptroller comptroller,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) public broadcaster returns (SablierV2LockupPro pro) {
        pro = new SablierV2LockupPro{ salt: ZERO_SALT }(admin, comptroller, maxFee, maxSegmentCount);
    }
}
