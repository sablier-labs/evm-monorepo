// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript as EvmUtilsBaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { SablierFactoryMerkleExecute } from "../../src/SablierFactoryMerkleExecute.sol";
import { SablierFactoryMerkleInstant } from "../../src/SablierFactoryMerkleInstant.sol";
import { SablierFactoryMerkleLL } from "../../src/SablierFactoryMerkleLL.sol";
import { SablierFactoryMerkleLT } from "../../src/SablierFactoryMerkleLT.sol";
import { SablierFactoryMerkleVCA } from "../../src/SablierFactoryMerkleVCA.sol";

/// @notice Deploys the FactoryMerkle contracts at deterministic addresses.
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicFactories is EvmUtilsBaseScript {
    string internal constant DEPLOYMENT_VERSION = "3.0.0";

    /// @dev Deploy via Forge.
    function run()
        public
        broadcast
        returns (
            SablierFactoryMerkleExecute factoryMerkleExecute,
            SablierFactoryMerkleInstant factoryMerkleInstant,
            SablierFactoryMerkleLL factoryMerkleLL,
            SablierFactoryMerkleLT factoryMerkleLT,
            SablierFactoryMerkleVCA factoryMerkleVCA
        )
    {
        factoryMerkleExecute = new SablierFactoryMerkleExecute{ salt: SALT }(getComptroller());
        factoryMerkleInstant = new SablierFactoryMerkleInstant{ salt: SALT }(getComptroller());
        factoryMerkleLL = new SablierFactoryMerkleLL{ salt: SALT }(getComptroller());
        factoryMerkleLT = new SablierFactoryMerkleLT{ salt: SALT }(getComptroller());
        factoryMerkleVCA = new SablierFactoryMerkleVCA{ salt: SALT }(getComptroller());
    }

    function getVersion() public pure override returns (string memory) {
        return DEPLOYMENT_VERSION;
    }
}
