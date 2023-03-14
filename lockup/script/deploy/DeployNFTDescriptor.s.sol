// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18 <0.9.0;

import { Script } from "forge-std/Script.sol";

import { SablierV2NFTDescriptor } from "../../src/SablierV2NFTDescriptor.sol";

import { BaseScript } from "../shared/Base.s.sol";

contract DeployNFTDescriptor is Script, BaseScript {
    function run() public virtual broadcaster returns (SablierV2NFTDescriptor initialNFTDescriptor) {
        initialNFTDescriptor = new SablierV2NFTDescriptor();
    }
}
