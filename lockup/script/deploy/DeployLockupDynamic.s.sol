// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19 <=0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "../../src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2NFTDescriptor } from "../../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2LockupDynamic } from "../../src/SablierV2LockupDynamic.sol";

import { BaseScript } from "../shared/Base.s.sol";

/// @notice Deploys {SablierV2LockupDynamic}.
contract DeployLockupDynamic is BaseScript {
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
        dynamic = new SablierV2LockupDynamic(
            initialAdmin,
            initialComptroller,
            initialNFTDescriptor,
            maxSegmentCount
        );
    }
}
