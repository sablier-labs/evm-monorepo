// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierFactoryMerkleInstant } from "../src/SablierFactoryMerkleInstant.sol";
import { SablierFactoryMerkleLL } from "../src/SablierFactoryMerkleLL.sol";
import { SablierFactoryMerkleLT } from "../src/SablierFactoryMerkleLT.sol";
import { SablierFactoryMerkleVCA } from "../src/SablierFactoryMerkleVCA.sol";
import { BaseScript } from "./Base.sol";

/// @notice Deploys the FactoryMerkle contracts at deterministic addresses.
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicFactories is BaseScript {
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
        address initialAdmin = protocolAdmin();
        uint256 initialMinFeeUSD = initialMinFeeUSD();
        address initialOracle = chainlinkOracle();
        factoryMerkleInstant =
            new SablierFactoryMerkleInstant{ salt: SALT }(initialAdmin, initialMinFeeUSD, initialOracle);
        factoryMerkleLL = new SablierFactoryMerkleLL{ salt: SALT }(initialAdmin, initialMinFeeUSD, initialOracle);
        factoryMerkleLT = new SablierFactoryMerkleLT{ salt: SALT }(initialAdmin, initialMinFeeUSD, initialOracle);
        factoryMerkleVCA = new SablierFactoryMerkleVCA{ salt: SALT }(initialAdmin, initialMinFeeUSD, initialOracle);
    }
}
