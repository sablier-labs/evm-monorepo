// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { ISablierV2NFTDescriptor } from "../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2LockupDynamic } from "../src/SablierV2LockupDynamic.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys {SablierV2LockupDynamic} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicLockupDynamic is BaseScript {
    function run(
        address initialAdmin,
        ISablierV2NFTDescriptor initialNFTDescriptor
    )
        public
        virtual
        broadcast
        returns (SablierV2LockupDynamic lockupDynamic)
    {
        bytes32 salt = constructCreate2Salt();
        lockupDynamic =
            new SablierV2LockupDynamic{ salt: salt }(initialAdmin, initialNFTDescriptor, segmentCountMap[block.chainid]);
    }
}
