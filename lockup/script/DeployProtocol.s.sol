// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { LockupNFTDescriptor } from "../src/LockupNFTDescriptor.sol";
import { SablierBatchLockup } from "../src/SablierBatchLockup.sol";
import { SablierLockup } from "../src/SablierLockup.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys the Lockup Protocol.
contract DeployProtocol is BaseScript {
    /// @dev Deploys the protocol with the admin set in `adminMap`.
    function run()
        public
        returns (LockupNFTDescriptor nftDescriptor, SablierLockup lockup, SablierBatchLockup batchLockup)
    {
        address initialAdmin = adminMap[block.chainid];
        (nftDescriptor, lockup, batchLockup) = _run(initialAdmin);
    }

    /// @dev Deploys the protocol with the given `initialAdmin`.
    function run(address initialAdmin)
        public
        returns (LockupNFTDescriptor nftDescriptor, SablierLockup lockup, SablierBatchLockup batchLockup)
    {
        (nftDescriptor, lockup, batchLockup) = _run(initialAdmin);
    }

    /// @dev Common logic for the run functions.
    function _run(address initialAdmin)
        internal
        broadcast
        returns (LockupNFTDescriptor nftDescriptor, SablierLockup lockup, SablierBatchLockup batchLockup)
    {
        batchLockup = new SablierBatchLockup();
        nftDescriptor = new LockupNFTDescriptor();
        lockup = new SablierLockup(initialAdmin, nftDescriptor, maxCountMap[block.chainid]);
    }
}
