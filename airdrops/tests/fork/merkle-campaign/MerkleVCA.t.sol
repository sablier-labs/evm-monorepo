// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierMerkleFactoryVCA } from "src/interfaces/ISablierMerkleFactoryVCA.sol";
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

        // Cast the {merkleFactoryVCA} contract as {ISablierMerkleFactoryBase}
        merkleFactoryBase = merkleFactoryVCA;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST-FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testForkFuzz_MerkleVCA(Params memory params, MerkleVCA.Timestamps memory timestamps) external {
        /*//////////////////////////////////////////////////////////////////////////
                                          CREATE
        //////////////////////////////////////////////////////////////////////////*/

        preCreateCampaign(params);

        vm.assume(timestamps.end > 0 && timestamps.start > 0);

        // Bound unlock start and end times.
        timestamps.start = boundUint40(timestamps.start, 1, getBlockTimestamp() - 1);
        timestamps.end = boundUint40(timestamps.end, timestamps.start + 1, MAX_UNIX_TIMESTAMP - 2 weeks);

        // The expiration must exceed the unlock end time by at least 1 week.
        if (timestamps.end > getBlockTimestamp() - 1 weeks) {
            params.expiration = boundUint40(params.expiration, timestamps.end + 1 weeks, MAX_UNIX_TIMESTAMP);
        } else {
            // If unlock end time is in the past, set expiration into the future to allow claiming.
            params.expiration = boundUint40(params.expiration, getBlockTimestamp() + 1, MAX_UNIX_TIMESTAMP);
        }

        vars.expectedMerkleCampaign = computeMerkleVCAAddress({
            campaignCreator: params.campaignOwner,
            campaignOwner: params.campaignOwner,
            expiration: params.expiration,
            merkleRoot: vars.merkleRoot,
            timestamps: timestamps,
            tokenAddress: FORK_TOKEN
        });

        MerkleVCA.ConstructorParams memory constructorParams = merkleVCAConstructorParams({
            campaignOwner: params.campaignOwner,
            expiration: params.expiration,
            merkleRoot: vars.merkleRoot,
            timestamps: timestamps,
            tokenAddress: FORK_TOKEN
        });

        vm.expectEmit({ emitter: address(merkleFactoryVCA) });
        emit ISablierMerkleFactoryVCA.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(vars.expectedMerkleCampaign),
            params: constructorParams,
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount,
            fee: vars.minimumFee,
            oracle: vars.oracle
        });

        merkleVCA = merkleFactoryVCA.createMerkleVCA(constructorParams, vars.aggregateAmount, vars.recipientCount);

        assertGt(address(merkleVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(merkleVCA), vars.expectedMerkleCampaign, "MerkleVCA contract does not match computed address");

        // Cast the {MerkleVCA} contract as {ISablierMerkleBase}
        merkleBase = merkleVCA;

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        preClaim(params);

        uint128 claimableAmount;

        if (getBlockTimestamp() >= timestamps.end) {
            claimableAmount = vars.amountToClaim;
        } else {
            // Calculate the claimable amount based on the elapsed time.
            uint40 elapsedTime = getBlockTimestamp() - timestamps.start;
            uint40 totalDuration = timestamps.end - timestamps.start;
            claimableAmount = uint128((uint256(vars.amountToClaim) * elapsedTime) / totalDuration);
        }

        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim(vars.indexToClaim, vars.recipientToClaim, claimableAmount, vars.amountToClaim);

        expectCallToClaimWithData({
            merkleLockup: address(merkleVCA),
            feeInWei: vars.minimumFeeInWei,
            index: vars.indexToClaim,
            recipient: vars.recipientToClaim,
            amount: vars.amountToClaim,
            merkleProof: vars.merkleProof
        });

        expectCallToTransfer({ token: FORK_TOKEN, to: vars.recipientToClaim, value: claimableAmount });

        merkleVCA.claim{ value: vars.minimumFeeInWei }({
            index: vars.indexToClaim,
            recipient: vars.recipientToClaim,
            amount: vars.amountToClaim,
            merkleProof: vars.merkleProof
        });

        assertTrue(merkleVCA.hasClaimed(vars.indexToClaim));

        uint256 expectedForgoneAmount = vars.amountToClaim - claimableAmount;
        assertEq(merkleVCA.forgoneAmount(), expectedForgoneAmount, "forgoneAmount");

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
