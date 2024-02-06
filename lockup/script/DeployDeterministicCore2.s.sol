// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2NFTDescriptor } from "../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2Comptroller } from "../src/SablierV2Comptroller.sol";
import { SablierV2LockupDynamic } from "../src/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../src/SablierV2LockupLinear.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys these contracts at deterministic addresses across chains, in the following order:
///
/// 1. {SablierV2Comptroller}
/// 2. {SablierV2LockupDynamic}
/// 3. {SablierV2LockupLinear}
///
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicCore2 is BaseScript {
    function run(
        address initialAdmin,
        ISablierV2NFTDescriptor nftDescriptor,
        uint256 maxSegmentCount
    )
        public
        virtual
        broadcast
        returns (
            SablierV2Comptroller comptroller,
            SablierV2LockupDynamic lockupDynamic,
            SablierV2LockupLinear lockupLinear
        )
    {
        bytes32 salt = constructCreate2Salt();
        comptroller = new SablierV2Comptroller{ salt: salt }(initialAdmin);
        lockupDynamic =
            new SablierV2LockupDynamic{ salt: salt }(initialAdmin, comptroller, nftDescriptor, maxSegmentCount);
        lockupLinear = new SablierV2LockupLinear{ salt: salt }(initialAdmin, comptroller, nftDescriptor);
    }
}
