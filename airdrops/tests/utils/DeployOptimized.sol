// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { CommonBase } from "forge-std/src/Base.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { ISablierMerkleFactoryInstant } from "../../src/interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleFactoryLL } from "../../src/interfaces/ISablierMerkleFactoryLL.sol";
import { ISablierMerkleFactoryLT } from "../../src/interfaces/ISablierMerkleFactoryLT.sol";
import { ISablierMerkleFactoryVCA } from "../../src/interfaces/ISablierMerkleFactoryVCA.sol";

abstract contract DeployOptimized is StdCheats, CommonBase {
    function deployOptimizedMerkleFactories(
        address initialAdmin,
        uint256 initialMinimumFee
    )
        internal
        returns (
            ISablierMerkleFactoryInstant merkleFactoryInstant,
            ISablierMerkleFactoryLL merkleFactoryLL,
            ISablierMerkleFactoryLT merkleFactoryLT,
            ISablierMerkleFactoryVCA merkleFactoryVCA
        )
    {
        merkleFactoryInstant = ISablierMerkleFactoryInstant(
            deployCode(
                "out-optimized/SablierMerkleFactoryInstant.sol/SablierMerkleFactoryInstant.json",
                abi.encode(initialAdmin, initialMinimumFee)
            )
        );
        merkleFactoryLL = ISablierMerkleFactoryLL(
            deployCode(
                "out-optimized/SablierMerkleFactoryLL.sol/SablierMerkleFactoryLL.json",
                abi.encode(initialAdmin, initialMinimumFee)
            )
        );
        merkleFactoryLT = ISablierMerkleFactoryLT(
            deployCode(
                "out-optimized/SablierMerkleFactoryLT.sol/SablierMerkleFactoryLT.json",
                abi.encode(initialAdmin, initialMinimumFee)
            )
        );
        merkleFactoryVCA = ISablierMerkleFactoryVCA(
            deployCode(
                "out-optimized/SablierMerkleFactoryVCA.sol/SablierMerkleFactoryVCA.json",
                abi.encode(initialAdmin, initialMinimumFee)
            )
        );
    }
}
