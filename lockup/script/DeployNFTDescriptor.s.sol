// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2NFTDescriptor } from "../src/SablierV2NFTDescriptor.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployNFTDescriptor is BaseScript {
    function run() public virtual broadcast returns (SablierV2NFTDescriptor nftDescriptor) {
        nftDescriptor = new SablierV2NFTDescriptor();
    }
}
