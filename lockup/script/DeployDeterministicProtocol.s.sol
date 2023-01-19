// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";
import { SablierV2LockupPro } from "src/SablierV2LockupPro.sol";

import { Common } from "./helpers/Common.s.sol";

/// @dev Deploys the entire Sablier V2 protocol at deterministic addresses across all chains. Reverts if
/// any contract has already been deployed via the deterministic CREATE2 factory.
///
/// The contracts are deployed in the following order:
///
/// 1. SablierV2Comptroller
/// 2. SablierV2LockupLinear
/// 3. SablierV2LockupPro
contract DeployDeterministicProtocol is Script, Common {
    /// @dev The presence of the salt instructs Forge to deploy the contract via a deterministic CREATE2 factory.
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(
        address admin,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    )
        public
        broadcaster
        returns (SablierV2Comptroller comptroller, SablierV2LockupLinear linear, SablierV2LockupPro pro)
    {
        // Deploy the SablierV2Comptroller contract.
        comptroller = new SablierV2Comptroller{ salt: ZERO_SALT }(admin);

        // Deploy the SablierV2LockupLinear contract.
        linear = new SablierV2LockupLinear{ salt: ZERO_SALT }(admin, comptroller, maxFee);

        // Deploy the SablierV2LockupPro contract.
        pro = new SablierV2LockupPro{ salt: ZERO_SALT }(admin, comptroller, maxFee, maxSegmentCount);
    }
}
