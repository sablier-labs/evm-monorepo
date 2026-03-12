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
    // Sepolia addresses
    IERC20 public constant DAI = IERC20(0x68194a729C2450ad26072b3D33ADaCbcef39D574);

    // See https://docs.sablier.com/guides/lockup/deployments for all deployments
    ISablierFactoryMerkleExecute public constant EXECUTE_FACTORY =
        ISablierFactoryMerkleExecute(0x832BF79bF135d474585171DB28c8feA962943Ec7);
    ISablierFactoryMerkleInstant public constant INSTANT_FACTORY =
        ISablierFactoryMerkleInstant(0x0F04F7eF61aAEda752d38c5b72A5F4BD69B9656A);
    ISablierFactoryMerkleLL public constant LL_FACTORY =
        ISablierFactoryMerkleLL(0xdF7Da7a69A90C6F60B170B304c4d8899d865f0f5);
    ISablierFactoryMerkleLT public constant LT_FACTORY =
        ISablierFactoryMerkleLT(0x603CDD1a2A517B6584330109f06cAb6B89c525d3);
    ISablierFactoryMerkleVCA public constant VCA_FACTORY =
        ISablierFactoryMerkleVCA(0x997ed890D6AeD711e885Bfc02D4F7F2aF92BbA02);
    ISablierLockup public constant LOCKUP = ISablierLockup(0xAcDc1b0686D38a4aDE97e73e242b30A96761Be64);

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
