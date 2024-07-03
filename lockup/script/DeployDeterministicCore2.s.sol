// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { ISablierV2NFTDescriptor } from "../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2LockupDynamic } from "../src/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../src/SablierV2LockupLinear.sol";
import { SablierV2LockupTranched } from "../src/SablierV2LockupTranched.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicCore2 is BaseScript {
    function run(
        address initialAdmin,
        ISablierV2NFTDescriptor nftDescriptor
    )
        public
        virtual
        broadcast
        returns (
            SablierV2LockupDynamic lockupDynamic,
            SablierV2LockupLinear lockupLinear,
            SablierV2LockupTranched lockupTranched
        )
    {
        bytes32 salt = constructCreate2Salt();
        lockupDynamic =
            new SablierV2LockupDynamic{ salt: salt }(initialAdmin, nftDescriptor, segmentCountMap[block.chainid]);
        lockupLinear = new SablierV2LockupLinear{ salt: salt }(initialAdmin, nftDescriptor);
        lockupTranched =
            new SablierV2LockupTranched{ salt: salt }(initialAdmin, nftDescriptor, trancheCountMap[block.chainid]);
    }
}
