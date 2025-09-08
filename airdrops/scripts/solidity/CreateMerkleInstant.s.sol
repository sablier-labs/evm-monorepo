// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseScript as EvmUtilsBaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { ISablierMerkleInstant } from "../../src/interfaces/ISablierMerkleInstant.sol";
import { SablierFactoryMerkleInstant } from "../../src/SablierFactoryMerkleInstant.sol";
import { MerkleInstant } from "../../src/types/DataTypes.sol";

/// @dev Creates a dummy MerkleInstant campaign.
contract CreateMerkleInstant is EvmUtilsBaseScript {
    /// @dev Deploy via Forge.
    function run() public broadcast returns (ISablierMerkleInstant merkleInstant) {
        // TODO: Load deployed addresses from Ethereum Mainnet.
        SablierFactoryMerkleInstant factory = new SablierFactoryMerkleInstant({ initialComptroller: getComptroller() });

        // Prepare the constructor parameters.
        MerkleInstant.ConstructorParams memory params;
        params.campaignName = "The Boys Instant";
        params.campaignStartTime = uint40(block.timestamp);
        params.expiration = uint40(block.timestamp + 30 days);
        params.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;
        params.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        params.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        params.token = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

        // The total amount to airdrop through the campaign.
        uint256 aggregateAmount = 10_000e18;

        // The number of eligible users for the airdrop.
        uint256 recipientCount = 100;

        // Deploy the MerkleInstant contract.
        merkleInstant = factory.createMerkleInstant(params, aggregateAmount, recipientCount);
    }
}
