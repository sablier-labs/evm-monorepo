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

    function testForkFuzz_MerkleVCA(Params memory params, uint40 endTime, uint40 startTime) external {
        /*//////////////////////////////////////////////////////////////////////////
                                          CREATE
        //////////////////////////////////////////////////////////////////////////*/

        preCreateCampaign(params);

        // Bound the start time.
        startTime = boundUint40(startTime, 1 seconds, getBlockTimestamp() - 1 seconds);

        // Bound the end time.
        endTime = boundUint40(endTime, startTime + 1, MAX_UNIX_TIMESTAMP - 2 weeks);

        // The expiration must exceed the end time by at least 1 week.
        if (endTime > getBlockTimestamp() - 1 weeks) {
            params.expiration = boundUint40(params.expiration, endTime + 1 weeks, MAX_UNIX_TIMESTAMP);
        } else {
            // If end time is in the past, set expiration into the future to allow claiming.
            params.expiration = boundUint40(params.expiration, getBlockTimestamp() + 1 seconds, MAX_UNIX_TIMESTAMP);
        }

        MerkleVCA.ConstructorParams memory constructorParams = merkleVCAConstructorParams({
            campaignCreator: params.campaignCreator,
            endTime: endTime,
            expiration: params.expiration,
            merkleRoot: vars.merkleRoot,
            startTime: startTime,
            tokenAddress: FORK_TOKEN
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

        // Calculate claim and forgone amount based on the vesting start and end time.
        (uint128 claimAmount, uint128 forgoneAmount) =
            calculateMerkleVCAAmounts({ fullAmount: vars.leafToClaim.amount, endTime: endTime, startTime: startTime });

        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim({
            index: vars.leafToClaim.index,
            recipient: vars.leafToClaim.recipient,
            claimAmount: claimAmount,
            forgoneAmount: forgoneAmount
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
            amount: vars.leafToClaim.amount,
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
}
