// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2NFTDescriptor } from "../../src/SablierV2NFTDescriptor.sol";

import { BaseScript } from "../shared/Base.s.sol";

contract DeployNFTDescriptor is BaseScript {
    function run() public virtual broadcaster returns (SablierV2NFTDescriptor initialNFTDescriptor) {
        initialNFTDescriptor = new SablierV2NFTDescriptor();
    }
}
