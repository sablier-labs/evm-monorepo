// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierMerkleFactory } from "../../src/periphery/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleInstant } from "../../src/periphery/interfaces/ISablierMerkleInstant.sol";
import { MerkleBase } from "../../src/periphery/types/DataTypes.sol";

import { BaseScript } from "../Base.s.sol";

contract CreateMerkleInstant is BaseScript {
    /// @dev Deploy via Forge.
    function run() public virtual broadcast returns (ISablierMerkleInstant merkleInstant) {
        // Prepare the constructor parameters.
        // TODO: Update address once deployed.
        ISablierMerkleFactory merkleFactory = ISablierMerkleFactory(0xF35aB407CF28012Ba57CAF5ee2f6d6E4420253bc);

        MerkleBase.ConstructorParams memory baseParams;
        baseParams.asset = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        baseParams.expiration = uint40(block.timestamp + 30 days);
        baseParams.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;
        baseParams.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        baseParams.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        baseParams.name = "The Boys Instant";

        uint256 campaignTotalAmount = 10_000e18;
        uint256 recipientCount = 100;

        // Deploy MerkleInstant contract.
        merkleInstant = merkleFactory.createMerkleInstant(baseParams, campaignTotalAmount, recipientCount);
    }
}
