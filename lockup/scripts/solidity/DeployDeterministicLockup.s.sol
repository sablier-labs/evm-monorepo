// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { ILockupNFTDescriptor } from "../../src/interfaces/ILockupNFTDescriptor.sol";
import { SablierLockup } from "../../src/SablierLockup.sol";

/// @notice Deploys {SablierLockup} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicLockup is BaseScript {
    function run(ILockupNFTDescriptor nftDescriptor) public broadcast returns (SablierLockup lockup) {
        lockup = new SablierLockup{ salt: SALT }(getComptroller(), address(nftDescriptor));
    }
}
