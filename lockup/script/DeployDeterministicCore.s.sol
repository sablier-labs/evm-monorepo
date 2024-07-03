// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierV2LockupDynamic } from "../src/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../src/SablierV2LockupLinear.sol";
import { SablierV2LockupTranched } from "../src/SablierV2LockupTranched.sol";
import { SablierV2NFTDescriptor } from "../src/SablierV2NFTDescriptor.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys all V2 Core contracts at deterministic addresses across chains.
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicCore is BaseScript {
    function run(address initialAdmin)
        public
        virtual
        broadcast
        returns (
            SablierV2LockupDynamic lockupDynamic,
            SablierV2LockupLinear lockupLinear,
            SablierV2LockupTranched lockupTranched,
            SablierV2NFTDescriptor nftDescriptor
        )
    {
        bytes32 salt = constructCreate2Salt();
        nftDescriptor = new SablierV2NFTDescriptor{ salt: salt }();
        lockupDynamic =
            new SablierV2LockupDynamic{ salt: salt }(initialAdmin, nftDescriptor, segmentCountMap[block.chainid]);
        lockupLinear = new SablierV2LockupLinear{ salt: salt }(initialAdmin, nftDescriptor);
        lockupTranched =
            new SablierV2LockupTranched{ salt: salt }(initialAdmin, nftDescriptor, trancheCountMap[block.chainid]);
    }
}
