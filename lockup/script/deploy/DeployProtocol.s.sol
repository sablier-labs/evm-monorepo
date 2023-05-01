// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19 <=0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2NFTDescriptor } from "../../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2Comptroller } from "../../src/SablierV2Comptroller.sol";
import { SablierV2LockupDynamic } from "../../src/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../../src/SablierV2LockupLinear.sol";

import { DeployComptroller } from "./DeployComptroller.s.sol";
import { DeployLockupDynamic } from "./DeployLockupDynamic.s.sol";
import { DeployLockupLinear } from "./DeployLockupLinear.s.sol";

/// @notice Deploys V2 Core in the following order:
///
/// 1. {SablierV2Comptroller}
/// 2. {SablierV2LockupDynamic}
/// 3. {SablierV2LockupLinear}
contract DeployProtocol is DeployComptroller, DeployLockupDynamic, DeployLockupLinear {
    function run(
        address initialAdmin,
        ISablierV2NFTDescriptor initialNFTDescriptor,
        uint256 maxSegmentCount
    )
        public
        virtual
        returns (SablierV2Comptroller comptroller, SablierV2LockupDynamic dynamic, SablierV2LockupLinear linear)
    {
        comptroller = DeployComptroller.run(initialAdmin);
        dynamic = DeployLockupDynamic.run(initialAdmin, comptroller, initialNFTDescriptor, maxSegmentCount);
        linear = DeployLockupLinear.run(initialAdmin, comptroller, initialNFTDescriptor);
    }
}
