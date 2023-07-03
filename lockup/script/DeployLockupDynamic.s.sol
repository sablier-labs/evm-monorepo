// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <=0.9.0;

import { ISablierV2Comptroller } from "../src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2NFTDescriptor } from "../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2LockupDynamic } from "../src/SablierV2LockupDynamic.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployLockupDynamic is BaseScript {
    function run(
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
        lockupDynamic = new SablierV2LockupDynamic(
            initialAdmin,
            initialComptroller,
            initialNFTDescriptor,
            maxSegmentCount
        );
    }
}
