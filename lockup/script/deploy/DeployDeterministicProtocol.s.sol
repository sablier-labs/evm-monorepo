// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19 <=0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2NFTDescriptor } from "../../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2Comptroller } from "../../src/SablierV2Comptroller.sol";
import { SablierV2LockupDynamic } from "../../src/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../../src/SablierV2LockupLinear.sol";

import { DeployDeterministicComptroller } from "./DeployDeterministicComptroller.s.sol";
import { DeployDeterministicLockupDynamic } from "./DeployDeterministicLockupDynamic.s.sol";
import { DeployDeterministicLockupLinear } from "./DeployDeterministicLockupLinear.s.sol";

/// @notice Deploys V2 Core at deterministic addresses across chains. The contracts are deployed in the following order:
///
/// 1. {SablierV2Comptroller}
/// 2. {SablierV2LockupDynamic}
/// 3. {SablierV2LockupLinear}
///
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicProtocol is
    DeployDeterministicComptroller,
    DeployDeterministicLockupDynamic,
    DeployDeterministicLockupLinear
{
    /// @dev The presence of the salt instructs Forge to deploy the contract via a deterministic CREATE2 factory.
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(
        address initialAdmin,
        ISablierV2NFTDescriptor initialNFTDescriptor,
        uint256 maxSegmentCount
    )
        public
        virtual
        returns (SablierV2Comptroller comptroller, SablierV2LockupDynamic dynamic, SablierV2LockupLinear linear)
    {
        comptroller = DeployDeterministicComptroller.run(initialAdmin);
        dynamic = DeployDeterministicLockupDynamic.run(initialAdmin, comptroller, initialNFTDescriptor, maxSegmentCount);
        linear = DeployDeterministicLockupLinear.run(initialAdmin, comptroller, initialNFTDescriptor);
    }
}
