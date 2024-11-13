// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { ILockupNFTDescriptor } from "../../src/core/interfaces/ILockupNFTDescriptor.sol";
import { SablierLockup } from "../../src/core/SablierLockup.sol";
import { BaseScript } from "../Base.s.sol";

/// @notice Deploys {SablierLockup} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicLockup is BaseScript {
    function run(
        address initialAdmin,
        ILockupNFTDescriptor nftDescriptor
    )
        public
        virtual
        broadcast
        returns (SablierLockup lockup)
    {
        bytes32 salt = constructCreate2Salt();
        lockup = new SablierLockup{ salt: salt }(initialAdmin, nftDescriptor, maxCountMap[block.chainid]);
    }
}
