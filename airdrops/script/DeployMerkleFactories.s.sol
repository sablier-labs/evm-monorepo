// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryInstant } from "../src/SablierMerkleFactoryInstant.sol";
import { SablierMerkleFactoryLL } from "../src/SablierMerkleFactoryLL.sol";
import { SablierMerkleFactoryLT } from "../src/SablierMerkleFactoryLT.sol";
import { SablierMerkleFactoryVCA } from "../src/SablierMerkleFactoryVCA.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys Merkle factory contracts.
contract DeployMerkleFactories is BaseScript {
    /// @dev Deploy via Forge.
    function run(uint256 initialMinimumFee)
        public
        broadcast
        returns (
            SablierMerkleFactoryInstant merkleFactoryInstant,
            SablierMerkleFactoryLL merkleFactoryLL,
            SablierMerkleFactoryLT merkleFactoryLT,
            SablierMerkleFactoryVCA merkleFactoryVCA
        )
    {
        address initialAdmin = adminMap[block.chainid];
        merkleFactoryInstant = new SablierMerkleFactoryInstant(initialAdmin, initialMinimumFee);
        merkleFactoryLL = new SablierMerkleFactoryLL(initialAdmin, initialMinimumFee);
        merkleFactoryLT = new SablierMerkleFactoryLT(initialAdmin, initialMinimumFee);
        merkleFactoryVCA = new SablierMerkleFactoryVCA(initialAdmin, initialMinimumFee);
    }
}
