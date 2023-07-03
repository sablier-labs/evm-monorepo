// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <=0.9.0;

import { SablierV2Comptroller } from "../src/SablierV2Comptroller.sol";
import { SablierV2LockupDynamic } from "../src/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../src/SablierV2LockupLinear.sol";
import { SablierV2NFTDescriptor } from "../src/SablierV2NFTDescriptor.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys all V2 Core contracts at deterministic addresses across chains, in the following order:
///
/// 1. {SablierV2Comptroller}
/// 2. {SablierV2NFTDescriptor}
/// 3. {SablierV2LockupDynamic}
/// 4. {SablierV2LockupLinear}
///
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicCore is BaseScript {
    /// @dev The presence of the salt instructs Forge to deploy the contract via a deterministic CREATE2 factory.
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(
        string memory create2Salt,
        address initialAdmin,
        uint256 maxSegmentCount
    )
        public
        virtual
        broadcast
        returns (
            SablierV2Comptroller comptroller,
            SablierV2LockupDynamic lockupDynamic,
            SablierV2LockupLinear lockupLinear,
            SablierV2NFTDescriptor nftDescriptor
        )
    {
        bytes32 salt = bytes32(abi.encodePacked(create2Salt));
        comptroller = new SablierV2Comptroller{ salt: salt}(initialAdmin);
        nftDescriptor = new SablierV2NFTDescriptor{ salt: salt}();
        // forgefmt: disable-next-line
        lockupDynamic = new SablierV2LockupDynamic{ salt: salt}(
            initialAdmin,
            comptroller,
            nftDescriptor,
            maxSegmentCount
        );
        lockupLinear = new SablierV2LockupLinear{ salt: salt}(initialAdmin, comptroller, nftDescriptor);
    }
}
