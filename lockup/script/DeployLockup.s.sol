// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { ILockupNFTDescriptor } from "../src/interfaces/ILockupNFTDescriptor.sol";
import { SablierLockup } from "../src/SablierLockup.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys {SablierLockup} contract.
contract DeployLockup is BaseScript {
    function run(
        address initialAdmin,
        ILockupNFTDescriptor nftDescriptor
    )
        public
        broadcast
        returns (SablierLockup lockup)
    {
        lockup = new SablierLockup(initialAdmin, nftDescriptor, maxCountMap[block.chainid]);
    }
}
