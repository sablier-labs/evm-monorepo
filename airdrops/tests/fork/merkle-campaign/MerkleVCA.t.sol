// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFactoryMerkleVCA } from "src/interfaces/ISablierFactoryMerkleVCA.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";

import { MerkleVCA } from "src/types/DataTypes.sol";

import { Fork_Test } from "./../Fork.t.sol";
import { MerkleBase_Fork_Test } from "./MerkleBase.t.sol";

abstract contract MerkleVCA_Fork_Test is MerkleBase_Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 tokenAddress) MerkleBase_Fork_Test(tokenAddress) { }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fork_Test.setUp();

        // Cast the {FactoryMerkleVCA} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleVCA;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST-FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testForkFuzz_MerkleVCA(Params memory params, uint40 vestingEndTime, uint40 vestingStartTime) external {
        /*//////////////////////////////////////////////////////////////////////////
                                          CREATE
        //////////////////////////////////////////////////////////////////////////*/

        preCreateCampaign(params);

        // Bound the vesting start time.
        vestingStartTime = boundUint40(vestingStartTime, 1 seconds, getBlockTimestamp() - 1 seconds);

        // Bound the vesting end time.
        vestingEndTime = boundUint40(vestingEndTime, vestingStartTime + 1 days, MAX_UNIX_TIMESTAMP - 2 weeks);

        // The expiration must exceed the vesting end time by at least 1 week.
        if (vestingEndTime > getBlockTimestamp() - 1 weeks) {
            params.expiration = boundUint40(params.expiration, vestingEndTime + 1 weeks, MAX_UNIX_TIMESTAMP);
        } else {
            // If vesting end time is in the past, set expiration into the future to allow claiming.
            params.expiration = boundUint40(params.expiration, getBlockTimestamp() + 1 seconds, MAX_UNIX_TIMESTAMP);
        }

        MerkleVCA.ConstructorParams memory constructorParams = merkleVCAConstructorParams({
            campaignCreator: params.campaignCreator,
            campaignStartTime: CAMPAIGN_START_TIME,
            expiration: params.expiration,
            merkleRoot: vars.merkleRoot,
            tokenAddress: FORK_TOKEN,
            unlockPercentage: VCA_UNLOCK_PERCENTAGE,
            vestingEndTime: vestingEndTime,
            vestingStartTime: vestingStartTime
        });

        vars.expectedMerkleCampaign =
            computeMerkleVCAAddress({ params: constructorParams, campaignCreator: params.campaignCreator });

        vm.expectEmit({ emitter: address(factoryMerkleVCA) });
        emit ISablierFactoryMerkleVCA.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(vars.expectedMerkleCampaign),
            params: constructorParams,
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.leavesData.length,
            minFeeUSD: vars.minFeeUSD,
            oracle: vars.oracle
        });

        merkleVCA = factoryMerkleVCA.createMerkleVCA(constructorParams, vars.aggregateAmount, vars.leavesData.length);

        assertLt(0, address(merkleVCA).code.length, "MerkleVCA contract not created");
        assertEq(address(merkleVCA), vars.expectedMerkleCampaign, "MerkleVCA contract does not match computed address");

        // Cast the {MerkleVCA} contract as {ISablierMerkleBase}
        merkleBase = merkleVCA;

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        preClaim(params);

        // Its not allowed to claim with a zero amount.
        _findAndWarpToClaimAmountGt0(vars.leafToClaim.amount, vestingEndTime);

        // Calculate claim and forgone amount based on the vesting start and end time.
        (uint128 claimAmount, uint128 forgoneAmount) = calculateMerkleVCAAmounts({
            fullAmount: vars.leafToClaim.amount,
            unlockPercentage: VCA_UNLOCK_PERCENTAGE,
            vestingEndTime: vestingEndTime,
            vestingStartTime: vestingStartTime
        });

        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim({
            index: vars.leafToClaim.index,
            recipient: vars.leafToClaim.recipient,
            claimAmount: claimAmount,
            forgoneAmount: forgoneAmount,
            to: vars.leafToClaim.recipient
        });

        expectCallToClaimWithData({
            merkleLockup: address(merkleVCA),
            feeInWei: vars.minFeeWei,
            index: vars.leafToClaim.index,
            recipient: vars.leafToClaim.recipient,
            amount: vars.leafToClaim.amount,
            merkleProof: vars.merkleProof
        });

        expectCallToTransfer({ token: FORK_TOKEN, to: vars.leafToClaim.recipient, value: claimAmount });

        merkleVCA.claim{ value: vars.minFeeWei }({
            index: vars.leafToClaim.index,
            recipient: vars.leafToClaim.recipient,
            fullAmount: vars.leafToClaim.amount,
            merkleProof: vars.merkleProof
        });

        assertTrue(merkleVCA.hasClaimed(vars.leafToClaim.index));

        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");

        /*//////////////////////////////////////////////////////////////////////////
                                        CLAWBACK
        //////////////////////////////////////////////////////////////////////////*/

        testClawback(params);

        /*//////////////////////////////////////////////////////////////////////////
                                        COLLECT-FEES
        //////////////////////////////////////////////////////////////////////////*/

        testCollectFees();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Binary searches for earliest timestamp when claim amount > 0, then warps to that time.
    function _findAndWarpToClaimAmountGt0(uint128 amount, uint40 vestingEndTime) private {
        uint40 currentTime = getBlockTimestamp();

        if (merkleVCA.calculateClaimAmount(amount, currentTime) > 0) {
            return;
        }

        while (currentTime < vestingEndTime) {
            uint40 mid = currentTime + (vestingEndTime - currentTime) / 2;

            if (merkleVCA.calculateClaimAmount(amount, mid) > 0) {
                vestingEndTime = mid;
            } else {
                currentTime = mid + 1;
            }
        }

        vm.warp(currentTime);
    }
}
