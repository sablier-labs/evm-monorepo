// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";
import { SablierV2LockupPro } from "src/SablierV2LockupPro.sol";

import { Common } from "./helpers/Common.s.sol";
import { DeployComptroller } from "./DeployComptroller.s.sol";

/// @notice Deploys the entire Sablier V2 protocol. The contracts are deployed in the following order:
///
/// 1. SablierV2Comptroller
/// 2. SablierV2LockupLinear
/// 3. SablierV2LockupPro
contract DeployProtocol is Script, Common {
    function run(
        address admin,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    )
        public
        broadcaster
        returns (SablierV2Comptroller comptroller, SablierV2LockupLinear linear, SablierV2LockupPro pro)
    {
        comptroller = new SablierV2Comptroller({ initialAdmin: admin });
        linear = new SablierV2LockupLinear({ initialAdmin: admin, initialComptroller: comptroller, maxFee: maxFee });
        pro = new SablierV2LockupPro({
            initialAdmin: admin,
            initialComptroller: comptroller,
            maxFee: maxFee,
            maxSegmentCount: maxSegmentCount
        });
    }
}
