// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierV2LockupDynamic } from "../src/core/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../src/core/SablierV2LockupLinear.sol";
import { SablierV2LockupTranched } from "../src/core/SablierV2LockupTranched.sol";
import { SablierV2NFTDescriptor } from "../src/core/SablierV2NFTDescriptor.sol";
import { SablierV2MerkleLockupFactory } from "../src/periphery/SablierV2MerkleLockupFactory.sol";
import { SablierV2BatchLockup } from "../src/periphery/SablierV2BatchLockup.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys the Sablier V2 Protocol.
contract DeployProtocol is BaseScript {
    /// @dev Deploy via Forge.
    function run(address initialAdmin)
        public
        virtual
        broadcast
        returns (
            SablierV2LockupDynamic lockupDynamic,
            SablierV2LockupLinear lockupLinear,
            SablierV2LockupTranched lockupTranched,
            SablierV2NFTDescriptor nftDescriptor,
            SablierV2BatchLockup batchLockup,
            SablierV2MerkleLockupFactory merkleLockupFactory
        )
    {
        // Deploy V2 Core.
        nftDescriptor = new SablierV2NFTDescriptor();
        lockupDynamic = new SablierV2LockupDynamic(initialAdmin, nftDescriptor, segmentCountMap[block.chainid]);
        lockupLinear = new SablierV2LockupLinear(initialAdmin, nftDescriptor);
        lockupTranched = new SablierV2LockupTranched(initialAdmin, nftDescriptor, trancheCountMap[block.chainid]);

        // Deploy V2 Periphery.
        batchLockup = new SablierV2BatchLockup();
        merkleLockupFactory = new SablierV2MerkleLockupFactory();
    }
}
