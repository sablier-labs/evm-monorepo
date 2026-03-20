// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { ISablierFactoryMerkleExecute } from "@sablier/airdrops/src/interfaces/ISablierFactoryMerkleExecute.sol";
import { ISablierFactoryMerkleInstant } from "@sablier/airdrops/src/interfaces/ISablierFactoryMerkleInstant.sol";
import { ISablierFactoryMerkleLL } from "@sablier/airdrops/src/interfaces/ISablierFactoryMerkleLL.sol";
import { ISablierFactoryMerkleLT } from "@sablier/airdrops/src/interfaces/ISablierFactoryMerkleLT.sol";
import { ISablierFactoryMerkleVCA } from "@sablier/airdrops/src/interfaces/ISablierFactoryMerkleVCA.sol";
import { ISablierMerkleExecute } from "@sablier/airdrops/src/interfaces/ISablierMerkleExecute.sol";
import { ISablierMerkleInstant } from "@sablier/airdrops/src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "@sablier/airdrops/src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "@sablier/airdrops/src/interfaces/ISablierMerkleLT.sol";
import { ISablierMerkleVCA } from "@sablier/airdrops/src/interfaces/ISablierMerkleVCA.sol";
import { MerkleInstant, MerkleLL, MerkleLT, MerkleVCA } from "@sablier/airdrops/src/types/DataTypes.sol";
import { MerkleExecute } from "@sablier/airdrops/src/types/MerkleExecute.sol";

/// @notice Example of how to create Merkle airdrop campaigns.
/// @dev This code is referenced in the docs: https://docs.sablier.com/guides/airdrops/examples/create-campaign
contract MerkleCreator {
    // Mainnet addresses
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    // See https://docs.sablier.com/guides/lockup/deployments for all deployments
    ISablierFactoryMerkleExecute public constant EXECUTE_FACTORY =
        ISablierFactoryMerkleExecute(0x75ca3677966737E70649336ee8f9be57AC9f74bA);
    ISablierFactoryMerkleInstant public constant INSTANT_FACTORY =
        ISablierFactoryMerkleInstant(0xb2855845067e126207DE2155Ad1c8AD5C495cb3F);
    ISablierFactoryMerkleLL public constant LL_FACTORY =
        ISablierFactoryMerkleLL(0x3210E9b8ed75f9E2Db00ef17167C775e658c2221);
    ISablierFactoryMerkleLT public constant LT_FACTORY =
        ISablierFactoryMerkleLT(0x239BD5431aDa12F09cA95d0a5d4388A5644268e9);
    ISablierFactoryMerkleVCA public constant VCA_FACTORY =
        ISablierFactoryMerkleVCA(0xe60Df8e04cE1616a06db8AD11ce71c05dDcB5D88);
    ISablierLockup public constant LOCKUP = ISablierLockup(0x93b37Bd5B6b278373217333Ac30D7E74c85fBDCB);

    function createMerkleExecute() public returns (ISablierMerkleExecute merkleExecute) {
        // Declare the constructor parameters of MerkleExecute.
        MerkleExecute.ConstructorParams memory params;

        // Set the parameters.
        params.token = DAI;
        params.campaignStartTime = uint40(block.timestamp);
        params.expiration = uint40(block.timestamp + 12 weeks); // The expiration of the campaign
        params.initialAdmin = address(0xBeeF); // Admin of the merkle lockup contract
        params.ipfsCID = "QmT5NvUtoM5nWFfrQdVrFtvGfKFmG7AHE8P34isapyhCxX"; // IPFS hash of the campaign metadata
        params.merkleRoot = 0x4e07408562bedb8b60ce05c1decfe3ad16b722309875f562c03d02d7aaacb123;
        params.campaignName = "My First Campaign"; // Unique campaign name
        params.target = address(0xCAFE); // Target contract to call on claim
        params.selector = bytes4(0x12345678); // Function selector to call on the target

        // The total amount of tokens you want to airdrop to your users.
        uint256 aggregateAmount = 100_000_000e18;

        // The total number of addresses you want to airdrop your tokens to.
        uint256 recipientCount = 10_000;

        // Deploy the MerkleExecute campaign contract. Recipients claim tokens and immediately execute a function on the
        // target contract (e.g., staking, lending).
        merkleExecute = EXECUTE_FACTORY.createMerkleExecute(params, aggregateAmount, recipientCount);
    }

    function createMerkleInstant() public virtual returns (ISablierMerkleInstant merkleInstant) {
        // Declare the constructor parameters of MerkleInstant.
        MerkleInstant.ConstructorParams memory params;

        // Set the parameters.
        params.token = DAI;
        params.campaignStartTime = uint40(block.timestamp);
        params.expiration = uint40(block.timestamp + 12 weeks); // The expiration of the campaign
        params.initialAdmin = address(0xBeeF); // Admin of the merkle lockup contract
        params.ipfsCID = "QmT5NvUtoM5nWFfrQdVrFtvGfKFmG7AHE8P34isapyhCxX"; // IPFS hash of the campaign metadata
        params.merkleRoot = 0x4e07408562bedb8b60ce05c1decfe3ad16b722309875f562c03d02d7aaacb123;
        params.campaignName = "My First Campaign"; // Unique campaign name

        // The total amount of tokens you want to airdrop to your users.
        uint256 aggregateAmount = 100_000_000e18;

        // The total number of addresses you want to airdrop your tokens to.
        uint256 recipientCount = 10_000;

        // Deploy the MerkleInstant campaign contract. The deployed contract will be completely owned by the campaign
        // admin. Recipients will interact with the deployed contract to claim their airdrop.
        merkleInstant = INSTANT_FACTORY.createMerkleInstant(params, aggregateAmount, recipientCount);
    }

    function createMerkleLL() public returns (ISablierMerkleLL merkleLL) {
        // Declare the constructor parameters of MerkleLL.
        MerkleLL.ConstructorParams memory params;

        // Set the parameters.
        params.token = DAI;
        params.campaignStartTime = uint40(block.timestamp);
        params.expiration = uint40(block.timestamp + 12 weeks); // The expiration of the campaign
        params.initialAdmin = address(0xBeeF); // Admin of the merkle lockup contract
        params.ipfsCID = "QmT5NvUtoM5nWFfrQdVrFtvGfKFmG7AHE8P34isapyhCxX"; // IPFS hash of the campaign metadata
        params.merkleRoot = 0x4e07408562bedb8b60ce05c1decfe3ad16b722309875f562c03d02d7aaacb123;
        params.campaignName = "My First Campaign"; // Unique campaign name
        params.shape = "A custom stream shape"; // Stream shape name for visualization in the UI
        params.lockup = LOCKUP;
        params.vestingStartTime = uint40(block.timestamp);
        params.cliffDuration = 30 days;
        params.cliffUnlockPercentage = ud60x18(0.01e18);
        params.granularity = 1 seconds; // Granularity for the linear stream
        params.startUnlockPercentage = ud60x18(0.01e18);
        params.totalDuration = 90 days;
        params.cancelable = false;
        params.transferable = true;

        // The total amount of tokens you want to airdrop to your users.
        uint256 aggregateAmount = 100_000_000e18;

        // The total number of addresses you want to airdrop your tokens to.
        uint256 recipientCount = 10_000;

        // Deploy the MerkleLL campaign contract. The deployed contract will be completely owned by the campaign admin.
        // Recipients will interact with the deployed contract to claim their airdrop.
        merkleLL = LL_FACTORY.createMerkleLL({
            campaignParams: params, aggregateAmount: aggregateAmount, recipientCount: recipientCount
        });
    }

    function createMerkleLT() public returns (ISablierMerkleLT merkleLT) {
        // Prepare the constructor parameters.
        MerkleLT.ConstructorParams memory params;

        // Set the parameters.
        params.token = DAI;
        params.campaignStartTime = uint40(block.timestamp);
        params.expiration = uint40(block.timestamp + 12 weeks); // The expiration of the campaign
        params.initialAdmin = address(0xBeeF); // Admin of the merkle lockup contract
        params.ipfsCID = "QmT5NvUtoM5nWFfrQdVrFtvGfKFmG7AHE8P34isapyhCxX"; // IPFS hash of the campaign metadata
        params.merkleRoot = 0x4e07408562bedb8b60ce05c1decfe3ad16b722309875f562c03d02d7aaacb123;
        params.campaignName = "My First Campaign"; // Unique campaign name
        params.shape = "A custom stream shape"; // Stream shape name for visualization in the UI
        params.lockup = LOCKUP;
        params.vestingStartTime = uint40(block.timestamp);
        params.cancelable = false;
        params.transferable = true;

        // The tranches with their unlock percentages and durations.
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = new MerkleLT.TrancheWithPercentage[](2);
        tranchesWithPercentages[0] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.5e18), duration: 30 days });
        tranchesWithPercentages[1] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.5e18), duration: 60 days });
        params.tranchesWithPercentages = tranchesWithPercentages;

        // The total amount of tokens you want to airdrop to your users.
        uint256 aggregateAmount = 100_000_000e18;

        // The total number of addresses you want to airdrop your tokens to.
        uint256 recipientCount = 10_000;

        // Deploy the MerkleLT campaign contract. The deployed contract will be completely owned by the campaign admin.
        // Recipients will interact with the deployed contract to claim their airdrop.
        merkleLT = LT_FACTORY.createMerkleLT({
            campaignParams: params, aggregateAmount: aggregateAmount, recipientCount: recipientCount
        });
    }

    function createMerkleVCA() public returns (ISablierMerkleVCA merkleVCA) {
        // Prepare the constructor parameters.
        MerkleVCA.ConstructorParams memory params;

        // Set the parameters.
        params.aggregateAmount = 100_000_000e18; // The total amount of tokens to airdrop
        params.token = DAI;
        params.campaignStartTime = uint40(block.timestamp);
        params.enableRedistribution = false;
        params.expiration = uint40(block.timestamp + 12 weeks); // The expiration of the campaign
        params.initialAdmin = address(0xBeeF); // Admin of the merkle lockup contract
        params.ipfsCID = "QmT5NvUtoM5nWFfrQdVrFtvGfKFmG7AHE8P34isapyhCxX"; // IPFS hash of the campaign metadata
        params.merkleRoot = 0x4e07408562bedb8b60ce05c1decfe3ad16b722309875f562c03d02d7aaacb123;
        params.campaignName = "My First Campaign"; // Unique campaign name
        params.unlockPercentage = ud60x18(0.25e18); // 25% unlocked immediately
        params.vestingStartTime = uint40(block.timestamp);
        params.vestingEndTime = uint40(block.timestamp + 90 days); // 90 days vesting period

        // The total number of addresses you want to airdrop your tokens to.
        uint256 recipientCount = 10_000;

        // Deploy the MerkleVCA campaign contract. The deployed contract will be completely owned by the campaign admin.
        // Recipients will interact with the deployed contract to claim their airdrop.
        merkleVCA = VCA_FACTORY.createMerkleVCA({ campaignParams: params, recipientCount: recipientCount });
    }
}
