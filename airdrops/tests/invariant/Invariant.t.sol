// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StdInvariant } from "forge-std/src/StdInvariant.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Base_Test } from "./../Base.t.sol";
import { MerkleInstantHandler } from "./handlers/MerkleInstantHandler.sol";
import { MerkleLLHandler } from "./handlers/MerkleLLHandler.sol";
import { MerkleLTHandler } from "./handlers/MerkleLTHandler.sol";
import { MerkleVCAHandler } from "./handlers/MerkleVCAHandler.sol";
import { Store } from "./stores/Store.sol";

/// @notice Invariants of Merkle Campaign contracts.
contract Invariant_Test is Base_Test, StdInvariant {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    MerkleInstantHandler internal merkleInstantHandler;
    MerkleLLHandler internal merkleLLHandler;
    MerkleLTHandler internal merkleLTHandler;
    MerkleVCAHandler internal merkleVCAHandler;

    Store internal store;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        Base_Test.setUp();

        // Deploy the Store contract.
        store = new Store(tokens);

        // Deploy the handlers.
        merkleInstantHandler = new MerkleInstantHandler(address(comptroller), store);
        merkleLLHandler = new MerkleLLHandler(address(comptroller), address(lockup), store);
        merkleLTHandler = new MerkleLTHandler(address(comptroller), address(lockup), store);
        merkleVCAHandler = new MerkleVCAHandler(address(comptroller), store);

        // Label the contracts.
        vm.label({ account: address(merkleInstantHandler), newLabel: "merkleInstantHandler" });
        vm.label({ account: address(merkleLLHandler), newLabel: "merkleLLHandler" });
        vm.label({ account: address(merkleLTHandler), newLabel: "merkleLTHandler" });
        vm.label({ account: address(merkleVCAHandler), newLabel: "merkleVCAHandler" });
        vm.label({ account: address(store), newLabel: "store" });

        // Target the flow handlers for invariant testing.
        targetContract(address(merkleInstantHandler));
        targetContract(address(merkleLLHandler));
        targetContract(address(merkleLTHandler));
        targetContract(address(merkleVCAHandler));

        // Append the excluded addresses.
        address[] memory excludedAddresses = new address[](5);
        excludedAddresses[0] = address(merkleInstantHandler);
        excludedAddresses[1] = address(merkleLLHandler);
        excludedAddresses[2] = address(merkleLTHandler);
        excludedAddresses[3] = address(merkleVCAHandler);
        excludedAddresses[4] = address(store);
        store.addExcludeAddresses(excludedAddresses);

        // Prevent the excluded addresses from being fuzzed as `msg.sender`.
        for (uint256 i = 0; i < excludedAddresses.length; ++i) {
            excludeSender(excludedAddresses[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 COMMON INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Balances invariants:
    /// - For non-VCA campaigns, the ERC-20 balance should be equal to the total deposit minus the sum of claimed and
    /// clawbacked amounts.
    /// - For VCA campaigns, the ERC-20 balance should be greater than or equal to the total deposit minus the sum of
    /// claimed, clawbacked, and redistribution rewards, due to rounding in the vesting calculation.
    function invariant_Balances() external view {
        address[] memory campaigns = store.getCampaigns();

        for (uint256 i = 0; i < campaigns.length; ++i) {
            address campaign = campaigns[i];

            // Get the token balance of the campaign.
            IERC20 token = ISablierMerkleBase(campaign).TOKEN();
            uint256 tokenBalance = token.balanceOf(address(campaign));

            // Get the total deposit into the campaign.
            uint256 totalDepositAmount = store.totalDepositAmount(campaign);

            // Get the total claimed amount from the campaign.
            uint256 totalClaimAmount = store.totalClaimAmount(campaign);

            // Get the total clawbacked amount from the campaign.
            uint256 totalClawbackAmount = store.totalClawbackAmount(campaign);

            if (store.isVcaCampaign(campaign)) {
                // For VCA campaigns, rewards are also transferred out of the campaign balance.
                uint256 totalRewardsDistributed = store.vcaTotalRewardsDistributed(campaign);

                // Use >= due to rounding in the vesting calculation.
                assertGe(
                    tokenBalance,
                    totalDepositAmount - totalClaimAmount - totalClawbackAmount - totalRewardsDistributed,
                    unicode"Invariant violation: token balance < total deposit - total claimed - total clawbacked - total rewards distributed"
                );
            } else {
                assertEq(
                    tokenBalance,
                    totalDepositAmount - totalClaimAmount - totalClawbackAmount,
                    unicode"Invariant violation: token balance != total deposit - total claimed - total clawbacked"
                );
            }
        }
    }

    /// @dev For a given index, the claim status should never change from true to false.
    function invariant_ClaimStatusTransition() external view {
        address[] memory campaigns = store.getCampaigns();

        for (uint256 i = 0; i < campaigns.length; ++i) {
            address campaign = campaigns[i];

            uint256[] memory claimedIndexes = store.getClaimedIndexes(campaign);

            for (uint256 j = 0; j < claimedIndexes.length; ++j) {
                uint256 claimedIndex = claimedIndexes[j];
                assertTrue(
                    ISablierMerkleBase(campaign).hasClaimed(claimedIndex),
                    unicode"Invariant violation: claim status changed from true to false"
                );
            }
        }
    }

    /// @dev The min fee in USD should never increase.
    function invariant_MinFeeUSDNeverIncreases() external view {
        address[] memory campaigns = store.getCampaigns();

        for (uint256 i = 0; i < campaigns.length; ++i) {
            address campaign = campaigns[i];

            assertLe(
                ISablierMerkleBase(campaign).minFeeUSD(),
                store.minFeeUSD(campaign),
                unicode"Invariant violation: minFeeUSD increased"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   VCA INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Invariants: For a VCA campaign,
    /// - Total forgone amount should be equal to the total full amount requested by users minus the total claimed amount.
    /// - If vesting has ended, total forgone amount should never change.
    function invariant_VcaTotalForgoneAmount() external view {
        address[] memory campaigns = store.getCampaigns();

        for (uint256 i = 0; i < campaigns.length; ++i) {
            if (!store.isVcaCampaign(campaigns[i])) continue;
            address merkleVCA = campaigns[i];

            assertEq(
                ISablierMerkleVCA(merkleVCA).totalForgoneAmount(),
                store.vcaTotalFullAmountRequested(merkleVCA) - store.totalClaimAmount(merkleVCA),
                unicode"Invariant violation: total forgone amount != total full amount requested - total claimed amount"
            );

            if (getBlockTimestamp() >= ISablierMerkleVCA(merkleVCA).VESTING_END_TIME()) {
                assertEq(
                    ISablierMerkleVCA(merkleVCA).totalForgoneAmount(),
                    store.previousVcaTotalForgoneAmount(merkleVCA),
                    unicode"Invariant violation: total forgone amount changed after vesting end time"
                );
            }
        }
    }

    /// @dev Invariants: For a VCA campaign, if redistribution is enabled and aggregate amount is correctly set,
    /// - The redistribution rewards for a fixed amount should never decrease.
    /// - If vesting has ended, redistribution rewards for a fixed amount should never change.
    /// - Rewards distributed should never exceed total forgone amount.
    function invariant_RedistributionRewardsGivenSufficientFunds() external view {
        address[] memory campaigns = store.getCampaigns();

        for (uint256 i = 0; i < campaigns.length; ++i) {
            if (!store.isVcaCampaign(campaigns[i])) continue;
            address merkleVCA = campaigns[i];

            // Skip if redistribution is disabled.
            if (!ISablierMerkleVCA(merkleVCA).isRedistributionEnabled()) continue;

            // Redistribution rewards for a fixed amount should never decrease.
            assertGe(
                ISablierMerkleVCA(merkleVCA).calculateRedistributionRewards({ fullAmount: 1e18 }),
                store.previousVcaRedistributionRewardsPer1e18(merkleVCA),
                unicode"Invariant violation: redistribution rewards decreased"
            );

            // If vesting has ended, redistribution rewards for a fixed amount should never change.
            if (getBlockTimestamp() >= ISablierMerkleVCA(merkleVCA).VESTING_END_TIME()) {
                assertEq(
                    ISablierMerkleVCA(merkleVCA).calculateRedistributionRewards({ fullAmount: 1e18 }),
                    store.previousVcaRedistributionRewardsPer1e18(merkleVCA),
                    unicode"Invariant violation: redistribution rewards changed after vesting end time"
                );
            }

            // Rewards distributed should never exceed total forgone amount.
            assertLe(
                store.vcaTotalRewardsDistributed(merkleVCA),
                ISablierMerkleVCA(merkleVCA).totalForgoneAmount(),
                unicode"Invariant violation: rewards distributed > total forgone amount"
            );
        }
    }

    /// @dev For a VCA campaign, the total forgone amount should never decrease.
    function invariant_TotalForgoneMonotonicity() external view {
        address[] memory campaigns = store.getCampaigns();

        for (uint256 i = 0; i < campaigns.length; ++i) {
            if (!store.isVcaCampaign(campaigns[i])) continue;
            assertLe(
                store.previousVcaTotalForgoneAmount(campaigns[i]),
                ISablierMerkleVCA(campaigns[i]).totalForgoneAmount(),
                unicode"Invariant violation: total forgone amount decreased"
            );
        }
    }
}
