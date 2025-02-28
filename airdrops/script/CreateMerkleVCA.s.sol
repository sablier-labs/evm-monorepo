// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { SablierMerkleFactoryVCA } from "src/SablierMerkleFactoryVCA.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";

/// @dev Creates a dummy MerkleVCA campaign.
contract CreateMerkleVCA is BaseScript {
    /// @dev Deploy via Forge.
    function run() public broadcast returns (ISablierMerkleVCA merkleVCA) {
        // TODO: Load deployed addresses from Ethereum mainnet.
        SablierMerkleFactoryVCA merkleFactory = new SablierMerkleFactoryVCA({
            initialAdmin: DEFAULT_SABLIER_ADMIN,
            initialMinimumFee: 0,
            initialOracle: address(0)
        });

        // Prepare the constructor parameters.
        MerkleVCA.ConstructorParams memory params;
        params.campaignName = "The Boys VCA";
        params.expiration = uint40(block.timestamp + 400 days);
        params.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;
        params.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        params.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        params.timestamps =
            MerkleVCA.Timestamps({ start: uint40(block.timestamp), end: uint40(block.timestamp + 365 days) });
        params.token = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

        // The total amount to airdrop through the campaign.
        uint256 campaignTotalAmount = 10_000e18;

        // The number of eligible users for the airdrop.
        uint256 recipientCount = 100;

        // Deploy the MerkleVCA contract.
        merkleVCA = merkleFactory.createMerkleVCA(params, campaignTotalAmount, recipientCount);
    }
}
