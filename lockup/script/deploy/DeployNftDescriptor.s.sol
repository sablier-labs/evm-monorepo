// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18 <0.9.0;

import { Script } from "forge-std/Script.sol";

import { SablierV2NftDescriptor } from "../../src/nft-descriptor/SablierV2NftDescriptor.sol";

import { BaseScript } from "../shared/Base.s.sol";

contract DeployNftDescriptor is Script, BaseScript {
    function run() public virtual broadcaster returns (SablierV2NftDescriptor nftDescriptor) {
        nftDescriptor = new SablierV2NftDescriptor();
    }
}
