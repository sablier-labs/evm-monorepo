// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript as EvmUtilsBaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { SablierFactoryMerkleInstant } from "../../src/SablierFactoryMerkleInstant.sol";
import { SablierFactoryMerkleLL } from "../../src/SablierFactoryMerkleLL.sol";
import { SablierFactoryMerkleLT } from "../../src/SablierFactoryMerkleLT.sol";
import { SablierFactoryMerkleVCA } from "../../src/SablierFactoryMerkleVCA.sol";

/// @notice Deploys the FactoryMerkle contracts at deterministic addresses.
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicFactories is EvmUtilsBaseScript {
    /// @dev Deploy via Forge.
    function run()
        public
        broadcast
        returns (
            SablierFactoryMerkleInstant factoryMerkleInstant,
            SablierFactoryMerkleLL factoryMerkleLL,
            SablierFactoryMerkleLT factoryMerkleLT,
            SablierFactoryMerkleVCA factoryMerkleVCA
        )
    {
        factoryMerkleInstant = new SablierFactoryMerkleInstant{ salt: SALT }(getComptroller());
        factoryMerkleLL = new SablierFactoryMerkleLL{ salt: SALT }(getComptroller());
        factoryMerkleLT = new SablierFactoryMerkleLT{ salt: SALT }(getComptroller());
        factoryMerkleVCA = new SablierFactoryMerkleVCA{ salt: SALT }(getComptroller());
    }
}
