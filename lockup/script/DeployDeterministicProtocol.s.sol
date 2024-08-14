// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { LockupNFTDescriptor } from "../src/core/LockupNFTDescriptor.sol";
import { SablierLockupDynamic } from "../src/core/SablierLockupDynamic.sol";
import { SablierLockupLinear } from "../src/core/SablierLockupLinear.sol";
import { SablierLockupTranched } from "../src/core/SablierLockupTranched.sol";
import { SablierMerkleFactory } from "../src/periphery/SablierMerkleFactory.sol";
import { SablierBatchLockup } from "../src/periphery/SablierBatchLockup.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys the Lockup Protocol at deterministic addresses across chains.
contract DeployDeterministicProtocol is BaseScript {
    /// @dev Deploy via Forge.
    function run(
        address initialAdmin
    )
        public
        virtual
        broadcast
        returns (
            LockupNFTDescriptor nftDescriptor,
            SablierLockupDynamic lockupDynamic,
            SablierLockupLinear lockupLinear,
            SablierLockupTranched lockupTranched,
            SablierBatchLockup batchLockup,
            SablierMerkleFactory merkleFactory
        )
    {
        bytes32 salt = constructCreate2Salt();

        // Deploy Core.
        nftDescriptor = new LockupNFTDescriptor{ salt: salt }();
        lockupDynamic =
            new SablierLockupDynamic{ salt: salt }(initialAdmin, nftDescriptor, segmentCountMap[block.chainid]);
        lockupLinear = new SablierLockupLinear{ salt: salt }(initialAdmin, nftDescriptor);
        lockupTranched =
            new SablierLockupTranched{ salt: salt }(initialAdmin, nftDescriptor, trancheCountMap[block.chainid]);

        // Deploy Periphery.
        batchLockup = new SablierBatchLockup{ salt: salt }();
        merkleFactory = new SablierMerkleFactory{ salt: salt }();
    }
}
