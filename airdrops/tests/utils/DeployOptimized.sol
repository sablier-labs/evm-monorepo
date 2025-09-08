// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { StdCheats } from "forge-std/src/StdCheats.sol";

import { ISablierFactoryMerkleInstant } from "../../src/interfaces/ISablierFactoryMerkleInstant.sol";
import { ISablierFactoryMerkleLL } from "../../src/interfaces/ISablierFactoryMerkleLL.sol";
import { ISablierFactoryMerkleLT } from "../../src/interfaces/ISablierFactoryMerkleLT.sol";
import { ISablierFactoryMerkleVCA } from "../../src/interfaces/ISablierFactoryMerkleVCA.sol";

abstract contract DeployOptimized is StdCheats {
    function deployOptimizedFactories(address initialComptroller)
        internal
        returns (
            ISablierFactoryMerkleInstant factoryMerkleInstant,
            ISablierFactoryMerkleLL factoryMerkleLL,
            ISablierFactoryMerkleLT factoryMerkleLT,
            ISablierFactoryMerkleVCA factoryMerkleVCA
        )
    {
        factoryMerkleInstant = ISablierFactoryMerkleInstant(
            deployCode(
                "out-optimized/SablierFactoryMerkleInstant.sol/SablierFactoryMerkleInstant.json",
                abi.encode(initialComptroller)
            )
        );
        factoryMerkleLL = ISablierFactoryMerkleLL(
            deployCode(
                "out-optimized/SablierFactoryMerkleLL.sol/SablierFactoryMerkleLL.json", abi.encode(initialComptroller)
            )
        );
        factoryMerkleLT = ISablierFactoryMerkleLT(
            deployCode(
                "out-optimized/SablierFactoryMerkleLT.sol/SablierFactoryMerkleLT.json", abi.encode(initialComptroller)
            )
        );
        factoryMerkleVCA = ISablierFactoryMerkleVCA(
            deployCode(
                "out-optimized/SablierFactoryMerkleVCA.sol/SablierFactoryMerkleVCA.json", abi.encode(initialComptroller)
            )
        );
    }
}
