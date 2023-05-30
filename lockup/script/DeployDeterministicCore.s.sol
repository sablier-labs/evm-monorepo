// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19 <=0.9.0;

import { ISablierV2NFTDescriptor } from "../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2Comptroller } from "../src/SablierV2Comptroller.sol";
import { SablierV2LockupDynamic } from "../src/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../src/SablierV2LockupLinear.sol";
import { SablierV2NFTDescriptor } from "../src/SablierV2NFTDescriptor.sol";

import { DeployDeterministicComptroller } from "./DeployDeterministicComptroller.s.sol";
import { DeployDeterministicLockupDynamic } from "./DeployDeterministicLockupDynamic.s.sol";
import { DeployDeterministicLockupLinear } from "./DeployDeterministicLockupLinear.s.sol";

/// @notice Deploys all V2 Core contracts at deterministic addresses across chains, in the following order:
///
/// 1. {SablierV2Comptroller}
/// 2. {SablierV2NFTDescriptor}
/// 3. {SablierV2LockupDynamic}
/// 4. {SablierV2LockupLinear}
///
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicCore is
    DeployDeterministicComptroller,
    DeployDeterministicLockupDynamic,
    DeployDeterministicLockupLinear
{
    /// @dev The presence of the salt instructs Forge to deploy the contract via a deterministic CREATE2 factory.
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(
        uint256 create2Salt,
        address initialAdmin,
        ISablierV2NFTDescriptor initialNFTDescriptor,
        uint256 maxSegmentCount
    )
        public
        virtual
        returns (
            SablierV2Comptroller comptroller,
            SablierV2LockupDynamic dynamic,
            SablierV2LockupLinear linear,
            SablierV2NFTDescriptor nftDescriptor
        )
    {
        comptroller = new SablierV2Comptroller{ salt: bytes32(create2Salt)}(initialAdmin);
        nftDescriptor = new SablierV2NFTDescriptor{ salt: bytes32(create2Salt)}();
        // forgefmt: disable-next-line
        dynamic = new SablierV2LockupDynamic{ salt: bytes32(create2Salt)}(
            initialAdmin,
            comptroller,
            initialNFTDescriptor,
            maxSegmentCount
        );
        linear = new SablierV2LockupLinear{ salt: bytes32(create2Salt)}(initialAdmin, comptroller, initialNFTDescriptor);
    }
}
