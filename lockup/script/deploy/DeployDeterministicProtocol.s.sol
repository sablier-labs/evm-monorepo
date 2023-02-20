// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";
import { SablierV2LockupPro } from "src/SablierV2LockupPro.sol";

import { DeployDeterministicComptroller } from "./DeployDeterministicComptroller.s.sol";
import { DeployDeterministicLockupLinear } from "./DeployDeterministicLockupLinear.s.sol";
import { DeployDeterministicLockupPro } from "./DeployDeterministicLockupPro.s.sol";

/// @dev Deploys the entire protocol at deterministic addresses across all chains. Reverts if any
/// contract has already been deployed.
///
/// The contracts are deployed in the following order:
///
/// 1. SablierV2Comptroller
/// 2. SablierV2LockupLinear
/// 3. SablierV2LockupPro
contract DeployDeterministicProtocol is
    DeployDeterministicComptroller,
    DeployDeterministicLockupLinear,
    DeployDeterministicLockupPro
{
    /// @dev The presence of the salt instructs Forge to deploy the contract via a deterministic CREATE2 factory.
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(
        address initialAdmin,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) public virtual returns (SablierV2Comptroller comptroller, SablierV2LockupLinear linear, SablierV2LockupPro pro) {
        // Deploy the SablierV2Comptroller contract.
        comptroller = DeployDeterministicComptroller.run(initialAdmin);

        // Deploy the SablierV2LockupLinear contract.
        linear = DeployDeterministicLockupLinear.run(initialAdmin, comptroller, maxFee);

        // Deploy the SablierV2LockupPro contract.
        pro = DeployDeterministicLockupPro.run(initialAdmin, comptroller, maxFee, maxSegmentCount);
    }
}
