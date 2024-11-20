// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { LockupNFTDescriptor } from "../../src/core/LockupNFTDescriptor.sol";
import { SablierBatchLockup } from "./../../src/core/SablierBatchLockup.sol";
import { SablierLockup } from "../../src/core/SablierLockup.sol";

import { BaseScript } from "../Base.s.sol";

/// @notice Deploys all Core contracts.
contract DeployCore is BaseScript {
    function run(address initialAdmin)
        public
        virtual
        broadcast
        returns (LockupNFTDescriptor nftDescriptor, SablierLockup lockup, SablierBatchLockup batchLockup)
    {
        nftDescriptor = new LockupNFTDescriptor();
        lockup = new SablierLockup(initialAdmin, nftDescriptor, maxCountMap[block.chainid]);
        batchLockup = new SablierBatchLockup();
    }
}
