// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { ILockupNFTDescriptor } from "../../src/core/interfaces/ILockupNFTDescriptor.sol";
import { SablierLockupDynamic } from "../../src/core/SablierLockupDynamic.sol";
import { SablierLockupLinear } from "../../src/core/SablierLockupLinear.sol";
import { SablierLockupTranched } from "../../src/core/SablierLockupTranched.sol";

import { BaseScript } from "../Base.s.sol";

/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicCore2 is BaseScript {
    function run(
        address initialAdmin,
        ILockupNFTDescriptor nftDescriptor
    )
        public
        virtual
        broadcast
        returns (
            SablierLockupDynamic lockupDynamic,
            SablierLockupLinear lockupLinear,
            SablierLockupTranched lockupTranched
        )
    {
        bytes32 salt = constructCreate2Salt();
        lockupDynamic =
            new SablierLockupDynamic{ salt: salt }(initialAdmin, nftDescriptor, segmentCountMap[block.chainid]);
        lockupLinear = new SablierLockupLinear{ salt: salt }(initialAdmin, nftDescriptor);
        lockupTranched =
            new SablierLockupTranched{ salt: salt }(initialAdmin, nftDescriptor, trancheCountMap[block.chainid]);
    }
}
