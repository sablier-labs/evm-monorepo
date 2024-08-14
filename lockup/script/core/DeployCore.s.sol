// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { LockupNFTDescriptor } from "../../src/core/LockupNFTDescriptor.sol";
import { SablierLockupDynamic } from "../../src/core/SablierLockupDynamic.sol";
import { SablierLockupLinear } from "../../src/core/SablierLockupLinear.sol";
import { SablierLockupTranched } from "../../src/core/SablierLockupTranched.sol";

import { BaseScript } from "../Base.s.sol";

/// @notice Deploys all Core contracts.
contract DeployCore is BaseScript {
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
            SablierLockupTranched lockupTranched
        )
    {
        nftDescriptor = new LockupNFTDescriptor();
        lockupDynamic = new SablierLockupDynamic(initialAdmin, nftDescriptor, segmentCountMap[block.chainid]);
        lockupLinear = new SablierLockupLinear(initialAdmin, nftDescriptor);
        lockupTranched = new SablierLockupTranched(initialAdmin, nftDescriptor, trancheCountMap[block.chainid]);
    }
}
