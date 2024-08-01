// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockupLinear } from "../../src/core/interfaces/ISablierLockupLinear.sol";
import { LockupLinear } from "../../src/core/types/DataTypes.sol";
import { ISablierMerkleLL } from "../../src/periphery/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLockupFactory } from "../../src/periphery/interfaces/ISablierMerkleLockupFactory.sol";
import { MerkleLockup } from "../../src/periphery/types/DataTypes.sol";

import { BaseScript } from "../Base.s.sol";

contract CreateMerkleLL is BaseScript {
    /// @dev Deploy via Forge.
    function run() public virtual broadcast returns (ISablierMerkleLL merkleLL) {
        // Prepare the constructor parameters.
        ISablierMerkleLockupFactory merkleLockupFactory =
            ISablierMerkleLockupFactory(0xF35aB407CF28012Ba57CAF5ee2f6d6E4420253bc); // TODO: Update address once deployed.

        MerkleLockup.ConstructorParams memory baseParams;
        baseParams.asset = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        baseParams.cancelable = true;
        baseParams.expiration = uint40(block.timestamp + 30 days);
        baseParams.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;
        baseParams.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        baseParams.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        baseParams.name = "The Boys LL";
        baseParams.transferable = true;

        // TODO: Update address once deployed.
        ISablierLockupLinear lockupLinear = ISablierLockupLinear(0x3962f6585946823440d274aD7C719B02b49DE51E);
        LockupLinear.Durations memory streamDurations;
        streamDurations.cliff = 0;
        streamDurations.total = 3600;
        uint256 campaignTotalAmount = 10_000e18;
        uint256 recipientCount = 100;

        // Deploy MerkleLL contract.
        merkleLL = merkleLockupFactory.createMerkleLL(
            baseParams, lockupLinear, streamDurations, campaignTotalAmount, recipientCount
        );
    }
}
