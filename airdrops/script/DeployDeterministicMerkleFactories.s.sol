// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { SablierMerkleFactoryInstant } from "../src/SablierMerkleFactoryInstant.sol";
import { SablierMerkleFactoryLL } from "../src/SablierMerkleFactoryLL.sol";
import { SablierMerkleFactoryLT } from "../src/SablierMerkleFactoryLT.sol";
import { SablierMerkleFactoryVCA } from "../src/SablierMerkleFactoryVCA.sol";

/// @notice Deploys Merkle factory contracts at deterministic address.
///
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicMerkleFactories is BaseScript {
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
        merkleFactoryInstant = new SablierMerkleFactoryInstant{ salt: SALT }(protocolAdmin(), initialMinimumFee);
        merkleFactoryLL = new SablierMerkleFactoryLL{ salt: SALT }(protocolAdmin(), initialMinimumFee);
        merkleFactoryLT = new SablierMerkleFactoryLT{ salt: SALT }(protocolAdmin(), initialMinimumFee);
        merkleFactoryVCA = new SablierMerkleFactoryVCA{ salt: SALT }(protocolAdmin(), initialMinimumFee);
    }
}
