// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import { BaseScript as EvmUtilsBaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

import { ISablierMerkleLL } from "../../src/interfaces/ISablierMerkleLL.sol";
import { SablierFactoryMerkleLL } from "../../src/SablierFactoryMerkleLL.sol";
import { MerkleLL } from "../../src/types/DataTypes.sol";

/// @dev Creates a dummy campaign to airdrop tokens through Lockup Linear.
contract CreateMerkleLL is EvmUtilsBaseScript {
    /// @dev Deploy via Forge.
    function run() public broadcast returns (ISablierMerkleLL merkleLL) {
        // TODO: Load deployed addresses from Ethereum Mainnet.
        SablierFactoryMerkleLL factory = new SablierFactoryMerkleLL({ initialComptroller: getComptroller() });

        // Prepare the constructor parameters.
        MerkleLL.ConstructorParams memory params;
        params.campaignName = "The Boys LL";
        params.campaignStartTime = uint40(block.timestamp);
        params.cancelable = true;
        params.cliffDuration = 30 days;
        params.cliffUnlockPercentage = ud60x18(0.01e18);
        params.expiration = uint40(block.timestamp + 30 days);
        params.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;
        params.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        params.lockup = ISablierLockup(0x7C01AA3783577E15fD7e272443D44B92d5b21056);
        params.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        params.shape = "LL";
        params.startUnlockPercentage = ud60x18(0.01e18);
        params.vestingStartTime = 0; // i.e. block.timestamp
        params.token = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        params.totalDuration = 90 days;
        params.transferable = true;

        uint256 aggregateAmount = 10_000e18;
        uint256 recipientCount = 100;

        // Deploy the MerkleLL contract.
        merkleLL = factory.createMerkleLL(params, aggregateAmount, recipientCount);
    }
}
