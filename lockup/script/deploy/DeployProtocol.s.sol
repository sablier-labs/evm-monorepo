// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

import { UD60x18 } from "@prb/math/UD60x18.sol";
import { Script } from "forge-std/Script.sol";

import { ISablierV2NFTDescriptor } from "../../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2Comptroller } from "../../src/SablierV2Comptroller.sol";
import { SablierV2LockupDynamic } from "../../src/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../../src/SablierV2LockupLinear.sol";

import { DeployComptroller } from "./DeployComptroller.s.sol";
import { DeployLockupDynamic } from "./DeployLockupDynamic.s.sol";
import { DeployLockupLinear } from "./DeployLockupLinear.s.sol";

/// @notice Deploys the entire protocol. The contracts are deployed in the following order:
///
/// 1. SablierV2Comptroller
/// 2. SablierV2LockupLinear
/// 3. SablierV2LockupDynamic
contract DeployProtocol is DeployComptroller, DeployLockupLinear, DeployLockupDynamic {
    function run(
        address initialAdmin,
        ISablierV2NFTDescriptor initialNFTDescriptor,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    )
        public
        virtual
        returns (SablierV2Comptroller comptroller, SablierV2LockupLinear linear, SablierV2LockupDynamic dynamic)
    {
        comptroller = DeployComptroller.run(initialAdmin);
        linear = DeployLockupLinear.run(initialAdmin, comptroller, initialNFTDescriptor, maxFee);
        dynamic = DeployLockupDynamic.run(initialAdmin, comptroller, initialNFTDescriptor, maxFee, maxSegmentCount);
    }
}
