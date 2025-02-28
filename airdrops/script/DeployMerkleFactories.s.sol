// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { SablierMerkleFactoryInstant } from "../src/SablierMerkleFactoryInstant.sol";
import { SablierMerkleFactoryLL } from "../src/SablierMerkleFactoryLL.sol";
import { SablierMerkleFactoryLT } from "../src/SablierMerkleFactoryLT.sol";
import { SablierMerkleFactoryVCA } from "../src/SablierMerkleFactoryVCA.sol";
import { ChainlinkPriceFeedAddresses } from "./ChainlinkPriceFeedAddresses.sol";

/// @notice Deploys Merkle factory contracts.
contract DeployMerkleFactories is BaseScript, ChainlinkPriceFeedAddresses {
    /// @dev The initial minimum fee, using Chainlink's 8 decimals format, where 1e8 is $1.
    uint256 private constant ONE_DOLLAR = 1e8;

    /// @dev Deploy via Forge.
    function run()
        public
        broadcast
        returns (
            SablierMerkleFactoryInstant merkleFactoryInstant,
            SablierMerkleFactoryLL merkleFactoryLL,
            SablierMerkleFactoryLT merkleFactoryLT,
            SablierMerkleFactoryVCA merkleFactoryVCA
        )
    {
        address initialAdmin = protocolAdmin();
        address initialOracle = getPriceFeedAddress();
        merkleFactoryInstant = new SablierMerkleFactoryInstant(initialAdmin, ONE_DOLLAR, initialOracle);
        merkleFactoryLL = new SablierMerkleFactoryLL(initialAdmin, ONE_DOLLAR, initialOracle);
        merkleFactoryLT = new SablierMerkleFactoryLT(initialAdmin, ONE_DOLLAR, initialOracle);
        merkleFactoryVCA = new SablierMerkleFactoryVCA(initialAdmin, ONE_DOLLAR, initialOracle);
    }
}
