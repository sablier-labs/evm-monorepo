// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18 <0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";
import { Script } from "forge-std/Script.sol";

import { SablierV2Comptroller } from "../../src/SablierV2Comptroller.sol";
import { SablierV2LockupLinear } from "../../src/SablierV2LockupLinear.sol";
import { SablierV2LockupPro } from "../../src/SablierV2LockupPro.sol";

import { DeployComptroller } from "./DeployComptroller.s.sol";
import { DeployLockupLinear } from "./DeployLockupLinear.s.sol";
import { DeployLockupPro } from "./DeployLockupPro.s.sol";

/// @notice Deploys the entire protocol. The contracts are deployed in the following order:
///
/// 1. SablierV2Comptroller
/// 2. SablierV2LockupLinear
/// 3. SablierV2LockupPro
contract DeployProtocol is DeployComptroller, DeployLockupLinear, DeployLockupPro {
    function run(
        address initialAdmin,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) public virtual returns (SablierV2Comptroller comptroller, SablierV2LockupLinear linear, SablierV2LockupPro pro) {
        comptroller = DeployComptroller.run(initialAdmin);
        linear = DeployLockupLinear.run(initialAdmin, comptroller, maxFee);
        pro = DeployLockupPro.run(initialAdmin, comptroller, maxFee, maxSegmentCount);
    }
}
