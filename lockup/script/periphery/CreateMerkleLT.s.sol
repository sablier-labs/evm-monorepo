// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/src/UD2x18.sol";

import { ISablierLockupTranched } from "../../src/core/interfaces/ISablierLockupTranched.sol";
import { ISablierMerkleFactory } from "../../src/periphery/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleLT } from "../../src/periphery/interfaces/ISablierMerkleLT.sol";
import { MerkleBase, MerkleLT } from "../../src/periphery/types/DataTypes.sol";

import { BaseScript } from "../Base.s.sol";

contract CreateMerkleLT is BaseScript {
    /// @dev Deploy via Forge.
    function run() public virtual broadcast returns (ISablierMerkleLT merkleLT) {
        // Prepare the constructor parameters.
        // TODO: Update address once deployed.
        ISablierMerkleFactory merkleFactory = ISablierMerkleFactory(0xF35aB407CF28012Ba57CAF5ee2f6d6E4420253bc);

        MerkleBase.ConstructorParams memory baseParams;
        baseParams.asset = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        baseParams.expiration = uint40(block.timestamp + 30 days);
        baseParams.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;
        baseParams.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        baseParams.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        baseParams.name = "The Boys LT";

        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = new MerkleLT.TrancheWithPercentage[](2);
        tranchesWithPercentages[0] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: UD2x18.wrap(50), duration: 3600 });
        tranchesWithPercentages[1] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: UD2x18.wrap(50), duration: 7200 });

        // Deploy MerkleLT contract.
        // TODO: Update address once deployed.
        merkleLT = merkleFactory.createMerkleLT({
            baseParams: baseParams,
            lockupTranched: ISablierLockupTranched(0xf86B359035208e4529686A1825F2D5BeE38c28A8),
            cancelable: true,
            transferable: true,
            tranchesWithPercentages: tranchesWithPercentages,
            aggregateAmount: 10_000e18,
            recipientCount: 100
        });
    }
}
