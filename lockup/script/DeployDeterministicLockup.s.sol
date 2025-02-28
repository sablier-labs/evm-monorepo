// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { ILockupNFTDescriptor } from "../src/interfaces/ILockupNFTDescriptor.sol";
import { SablierLockup } from "../src/SablierLockup.sol";
import { MaxCountScript } from "./MaxCount.s.sol";

/// @notice Deploys {SablierLockup} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicLockup is MaxCountScript {
    function run(ILockupNFTDescriptor nftDescriptor) public broadcast returns (SablierLockup lockup) {
        lockup = new SablierLockup{ salt: SALT }(protocolAdmin(), nftDescriptor, maxCountMap[block.chainid]);
    }
}
