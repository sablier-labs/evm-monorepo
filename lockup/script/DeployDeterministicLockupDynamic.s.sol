// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <=0.9.0;

import { ISablierV2Comptroller } from "../src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2NFTDescriptor } from "../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2LockupDynamic } from "../src/SablierV2LockupDynamic.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys {SablierV2LockupDynamic} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicLockupDynamic is BaseScript {
    /// @dev The presence of the salt instructs Forge to deploy contracts via this deterministic CREATE2 factory:
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(
        string memory create2Salt,
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        ISablierV2NFTDescriptor initialNFTDescriptor,
        uint256 maxSegmentCount
    )
        public
        virtual
        broadcast
        returns (SablierV2LockupDynamic lockupDynamic)
    {
        lockupDynamic = new SablierV2LockupDynamic{ salt: bytes32(abi.encodePacked(create2Salt)) }(
            initialAdmin,
            initialComptroller,
            initialNFTDescriptor,
            maxSegmentCount
        );
    }
}
