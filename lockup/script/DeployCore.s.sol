// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19 <=0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2NFTDescriptor } from "../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2Comptroller } from "../src/SablierV2Comptroller.sol";
import { SablierV2LockupDynamic } from "../src/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../src/SablierV2LockupLinear.sol";
import { SablierV2NFTDescriptor } from "../src/SablierV2NFTDescriptor.sol";

/// @notice Deploys all V2 Core contract in the following order:
///
/// 1. {SablierV2Comptroller}
/// 2. {SablierV2NFTDescriptor}
/// 3. {SablierV2LockupDynamic}
/// 4. {SablierV2LockupLinear}
contract DeployCore {
    function run(
        address initialAdmin,
        uint256 maxSegmentCount
    )
        public
        virtual
        returns (
            SablierV2Comptroller comptroller,
            SablierV2LockupDynamic dynamic,
            SablierV2LockupLinear linear,
            SablierV2NFTDescriptor nftDescriptor
        )
    {
        comptroller = new SablierV2Comptroller(initialAdmin);
        nftDescriptor = new SablierV2NFTDescriptor();
        dynamic = new SablierV2LockupDynamic(initialAdmin, comptroller, nftDescriptor, maxSegmentCount);
        linear = new SablierV2LockupLinear(initialAdmin, comptroller, nftDescriptor);
    }
}
