// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockupLinear } from "../../src/core/interfaces/ISablierLockupLinear.sol";
import { ISablierMerkleFactory } from "../../src/periphery/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleLL } from "../../src/periphery/interfaces/ISablierMerkleLL.sol";
import { MerkleBase, MerkleLL } from "../../src/periphery/types/DataTypes.sol";

import { BaseScript } from "../Base.s.sol";

contract CreateMerkleLL is BaseScript {
    /// @dev Deploy via Forge.
    function run() public virtual broadcast returns (ISablierMerkleLL merkleLL) {
        // Prepare the constructor parameters.
        // TODO: Update address once deployed.
        ISablierMerkleFactory merkleFactory = ISablierMerkleFactory(0xF35aB407CF28012Ba57CAF5ee2f6d6E4420253bc);

        MerkleBase.ConstructorParams memory baseParams;
        baseParams.asset = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        baseParams.expiration = uint40(block.timestamp + 30 days);
        baseParams.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;
        baseParams.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        baseParams.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        baseParams.name = "The Boys LL";

        // Deploy MerkleLL contract.
        // TODO: Update address once deployed.
        merkleLL = merkleFactory.createMerkleLL({
            baseParams: baseParams,
            lockupLinear: ISablierLockupLinear(0x3962f6585946823440d274aD7C719B02b49DE51E),
            cancelable: true,
            transferable: true,
            schedule: MerkleLL.Schedule({
                startTime: 0, // i.e. block.timestamp
                cliffDuration: 30 days,
                totalDuration: 90 days
            }),
            aggregateAmount: 10_000e18,
            recipientCount: 100
        });
    }
}
