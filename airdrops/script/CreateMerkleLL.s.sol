// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

import { ISablierMerkleFactory } from "../src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleLL } from "../src/interfaces/ISablierMerkleLL.sol";
import { MerkleBase, MerkleLL } from "../src/types/DataTypes.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev Creates a dummy campaign to airdrop tokens through Lockup Linear.
contract CreateMerkleLL is BaseScript {
    /// @dev Deploy via Forge.
    function run() public virtual broadcast returns (ISablierMerkleLL merkleLL) {
        // TODO: Update address once deployed.
        ISablierMerkleFactory merkleFactory = ISablierMerkleFactory(0xF35aB407CF28012Ba57CAF5ee2f6d6E4420253bc);

        // Prepare the constructor parameters.
        MerkleBase.ConstructorParams memory baseParams;

        // The token to distribute through the campaign.
        baseParams.token = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

        // The campaign will expire in 30 days.
        baseParams.expiration = uint40(block.timestamp + 30 days);

        // The admin of the campaign.
        baseParams.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;

        // Dummy values for the campaign name, IPFS CID, and the Merkle root hash.
        baseParams.campaignName = "The Boys LL";
        baseParams.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        baseParams.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;

        // Deploy the MerkleLL contract.
        // TODO: Update address once deployed.
        merkleLL = merkleFactory.createMerkleLL({
            baseParams: baseParams,
            lockup: ISablierLockup(0x3962f6585946823440d274aD7C719B02b49DE51E),
            cancelable: true,
            transferable: true,
            schedule: MerkleLL.Schedule({
                startTime: 0, // i.e. block.timestamp
                startAmount: 10e18,
                cliffDuration: 30 days,
                cliffAmount: 10e18,
                totalDuration: 90 days
            }),
            aggregateAmount: 10_000e18,
            recipientCount: 100
        });
    }
}
