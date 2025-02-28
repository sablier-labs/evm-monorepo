// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { ISablierMerkleLL } from "./../src/interfaces/ISablierMerkleLL.sol";
import { SablierMerkleFactoryLL } from "./../src/SablierMerkleFactoryLL.sol";
import { MerkleLL } from "./../src/types/DataTypes.sol";

/// @dev Creates a dummy campaign to airdrop tokens through Lockup Linear.
contract CreateMerkleLL is BaseScript {
    /// @dev Deploy via Forge.
    function run() public broadcast returns (ISablierMerkleLL merkleLL) {
        // TODO: Load deployed addresses from Ethereum mainnet.
        SablierMerkleFactoryLL merkleFactory = new SablierMerkleFactoryLL({
            initialAdmin: DEFAULT_SABLIER_ADMIN,
            initialMinimumFee: 0,
            initialOracle: address(0)
        });

        // Prepare the constructor parameters.
        MerkleLL.ConstructorParams memory params;
        params.campaignName = "The Boys LL";
        params.cancelable = true;
        params.expiration = uint40(block.timestamp + 30 days);
        params.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;
        params.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        params.lockup = ISablierLockup(0x7C01AA3783577E15fD7e272443D44B92d5b21056);
        params.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        params.shape = "LL";
        params.schedule = MerkleLL.Schedule({
            startTime: 0, // i.e. block.timestamp
            startPercentage: ud2x18(0.01e18),
            cliffDuration: 30 days,
            cliffPercentage: ud2x18(0.01e18),
            totalDuration: 90 days
        });
        params.token = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        params.transferable = true;
        uint256 aggregateAmount = 10_000e18;
        uint256 recipientCount = 100;

        // Deploy the MerkleLL contract.
        merkleLL = merkleFactory.createMerkleLL(params, aggregateAmount, recipientCount);
    }
}
