// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { ILockupNFTDescriptor } from "../../src/core/interfaces/ILockupNFTDescriptor.sol";
import { SablierLockupTranched } from "../../src/core/SablierLockupTranched.sol";

import { BaseScript } from "../Base.s.sol";

/// @dev Deploys {SablierLockupTranched} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicLockupTranched is BaseScript {
    function run(
        address initialAdmin,
        ILockupNFTDescriptor initialNFTDescriptor
    )
        public
        virtual
        broadcast
        returns (SablierLockupTranched lockupTranched)
    {
        bytes32 salt = constructCreate2Salt();
        lockupTranched =
            new SablierLockupTranched{ salt: salt }(initialAdmin, initialNFTDescriptor, trancheCountMap[block.chainid]);
    }
}
