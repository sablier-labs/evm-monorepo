// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { LockupNFTDescriptor } from "../../src/core/LockupNFTDescriptor.sol";
import { SablierLockupDynamic } from "../../src/core/SablierLockupDynamic.sol";
import { SablierLockupLinear } from "../../src/core/SablierLockupLinear.sol";
import { SablierLockupTranched } from "../../src/core/SablierLockupTranched.sol";
import { SablierBatchLockup } from "../../src/periphery/SablierBatchLockup.sol";
import { SablierMerkleFactory } from "../../src/periphery/SablierMerkleFactory.sol";

import { DeploymentLogger } from "./DeploymentLogger.s.sol";

/// @notice Deploys the Lockup Protocol.
contract DeployProtocol is DeploymentLogger("non_deterministic") {
    /// @dev Deploys the protocol with the admin set in `adminMap`.
    function run()
        public
        virtual
        broadcast
        returns (
            LockupNFTDescriptor nftDescriptor,
            SablierLockupDynamic lockupDynamic,
            SablierLockupLinear lockupLinear,
            SablierLockupTranched lockupTranched,
            SablierBatchLockup batchLockup,
            SablierMerkleFactory merkleLockupFactory
        )
    {
        address initialAdmin = adminMap[block.chainid];

        (nftDescriptor, lockupDynamic, lockupLinear, lockupTranched, batchLockup, merkleLockupFactory) =
            _run(initialAdmin);
    }

    /// @dev Deploys the protocol with the given `initialAdmin`.
    function run(address initialAdmin)
        internal
        returns (
            LockupNFTDescriptor nftDescriptor,
            SablierLockupDynamic lockupDynamic,
            SablierLockupLinear lockupLinear,
            SablierLockupTranched lockupTranched,
            SablierBatchLockup batchLockup,
            SablierMerkleFactory merkleLockupFactory
        )
    {
        (nftDescriptor, lockupDynamic, lockupLinear, lockupTranched, batchLockup, merkleLockupFactory) =
            _run(initialAdmin);
    }

    /// @dev Common logic for the run functions.
    function _run(address initialAdmin)
        internal
        returns (
            LockupNFTDescriptor nftDescriptor,
            SablierLockupDynamic lockupDynamic,
            SablierLockupLinear lockupLinear,
            SablierLockupTranched lockupTranched,
            SablierBatchLockup batchLockup,
            SablierMerkleFactory merkleLockupFactory
        )
    {
        nftDescriptor = new LockupNFTDescriptor();
        lockupDynamic = new SablierLockupDynamic(initialAdmin, nftDescriptor, segmentCountMap[block.chainid]);
        lockupLinear = new SablierLockupLinear(initialAdmin, nftDescriptor);
        lockupTranched = new SablierLockupTranched(initialAdmin, nftDescriptor, trancheCountMap[block.chainid]);
        batchLockup = new SablierBatchLockup();
        merkleLockupFactory = new SablierMerkleFactory(initialAdmin);

        appendToFileDeployedAddresses(
            address(lockupDynamic),
            address(lockupLinear),
            address(lockupTranched),
            address(nftDescriptor),
            address(batchLockup),
            address(merkleLockupFactory)
        );
    }
}
