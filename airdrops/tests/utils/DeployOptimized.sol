// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { CommonBase } from "forge-std/src/Base.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { ISablierMerkleFactory } from "../../src/interfaces/ISablierMerkleFactory.sol";

abstract contract DeployOptimized is StdCheats, CommonBase {
    function deployOptimizedMerkleFactory(address initialAdmin) internal returns (ISablierMerkleFactory) {
        return ISablierMerkleFactory(
            deployCode("out-optimized/SablierMerkleFactory.sol/SablierMerkleFactory.json", abi.encode(initialAdmin))
        );
    }
}
