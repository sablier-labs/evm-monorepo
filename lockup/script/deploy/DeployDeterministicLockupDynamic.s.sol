// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19 <=0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "../../src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2NFTDescriptor } from "../../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2LockupDynamic } from "../../src/SablierV2LockupDynamic.sol";

import { BaseScript } from "../shared/Base.s.sol";

/// @notice Deploys {SablierV2LockupDynamic} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicLockupDynamic is BaseScript {
    /// @dev The presence of the salt instructs Forge to deploy contracts via this deterministic CREATE2 factory:
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        ISablierV2NFTDescriptor initialNFTDescriptor,
        uint256 maxSegmentCount
    )
        public
        virtual
        broadcaster
        returns (SablierV2LockupDynamic dynamic)
    {
        dynamic = new SablierV2LockupDynamic{ salt: ZERO_SALT }(
            initialAdmin,
            initialComptroller,
            initialNFTDescriptor,
            maxSegmentCount
        );
    }
}
