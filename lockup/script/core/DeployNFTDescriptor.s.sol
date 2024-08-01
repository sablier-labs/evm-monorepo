// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { LockupNFTDescriptor } from "../../src/core/LockupNFTDescriptor.sol";

import { BaseScript } from "../Base.s.sol";

contract DeployNFTDescriptor is BaseScript {
    function run() public virtual broadcast returns (LockupNFTDescriptor nftDescriptor) {
        nftDescriptor = new LockupNFTDescriptor();
    }
}
