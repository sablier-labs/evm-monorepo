// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactory } from "../src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleInstant } from "../src/interfaces/ISablierMerkleInstant.sol";
import { MerkleBase } from "../src/types/DataTypes.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev Creates a dummy campaign to airdrop tokens instantly.
contract CreateMerkleInstant is BaseScript {
    /// @dev Deploy via Forge.
    function run() public virtual broadcast returns (ISablierMerkleInstant merkleInstant) {
        // TODO: Update address once deployed.
        ISablierMerkleFactory merkleFactory = ISablierMerkleFactory(0xF35aB407CF28012Ba57CAF5ee2f6d6E4420253bc);

        // Prepare the constructor parameters.
        MerkleBase.ConstructorParams memory baseParams;

        // The campaign will expire in 30 days.
        baseParams.expiration = uint40(block.timestamp + 30 days);

        // The admin of the campaign.
        baseParams.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;

        // A dummy IPFS CID where the campaign's metadata can be stored.
        baseParams.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";

        // A dummy Merkle root hash.
        baseParams.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;

        // A dummy name for the campaign.
        baseParams.name = "The Boys Instant";

        // The total amount to airdrop through the campaign.
        uint256 campaignTotalAmount = 10_000e18;

        // The number of eligible users for the airdrop.
        uint256 recipientCount = 100;

        // Deploy the MerkleInstant contract.
        merkleInstant = merkleFactory.createMerkleInstant(baseParams, campaignTotalAmount, recipientCount);
    }
}
