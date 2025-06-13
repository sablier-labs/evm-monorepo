// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";
import { SablierFactoryMerkleInstant } from "../../src/SablierFactoryMerkleInstant.sol";
import { SablierFactoryMerkleLL } from "../../src/SablierFactoryMerkleLL.sol";
import { SablierFactoryMerkleLT } from "../../src/SablierFactoryMerkleLT.sol";
import { SablierFactoryMerkleVCA } from "../../src/SablierFactoryMerkleVCA.sol";

/// @notice Deploys the FactoryMerkle contracts.
contract DeployFactories is BaseScript {
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
        factoryMerkleInstant = new SablierFactoryMerkleInstant(initialAdmin, initialMinFeeUSD, initialOracle);
        factoryMerkleLL = new SablierFactoryMerkleLL(initialAdmin, initialMinFeeUSD, initialOracle);
        factoryMerkleLT = new SablierFactoryMerkleLT(initialAdmin, initialMinFeeUSD, initialOracle);
        factoryMerkleVCA = new SablierFactoryMerkleVCA(initialAdmin, initialMinFeeUSD, initialOracle);
    }
}
