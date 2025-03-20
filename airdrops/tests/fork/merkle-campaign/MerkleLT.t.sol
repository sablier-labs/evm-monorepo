// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Lockup } from "@sablier/lockup/src/types/DataTypes.sol";

import { ISablierFactoryMerkleLT } from "src/interfaces/ISablierFactoryMerkleLT.sol";
import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Fork_Test } from "./../Fork.t.sol";
import { MerkleBase_Fork_Test } from "./MerkleBase.t.sol";

abstract contract MerkleLT_Fork_Test is MerkleBase_Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 tokenAddress) MerkleBase_Fork_Test(tokenAddress) { }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fork_Test.setUp();

        // Cast the {FactoryMerkleLT} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleLT;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST-FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testForkFuzz_MerkleLT(Params memory params, uint40 startTime) external {
        /*//////////////////////////////////////////////////////////////////////////
                                          CREATE
        //////////////////////////////////////////////////////////////////////////*/

        uint40 expectedStartTime;

        // If the start time is not zero, bound it to a reasonable range so that schedule end time can be in the past,
        // present and future.
        if (startTime != 0) {
            startTime =
                boundUint40(startTime, getBlockTimestamp() - TOTAL_DURATION - 10 days, getBlockTimestamp() + 2 days);
            expectedStartTime = startTime;
        } else {
            expectedStartTime = getBlockTimestamp();
        }

        preCreateCampaign(params);

        MerkleLT.ConstructorParams memory constructorParams = merkleLTConstructorParams({
            campaignCreator: params.campaignCreator,
            expiration: params.expiration,
            lockupAddress: lockup,
            merkleRoot: vars.merkleRoot,
            startTime: startTime,
            tokenAddress: FORK_TOKEN
        });

        vars.expectedMerkleCampaign =
            computeMerkleLTAddress({ params: constructorParams, campaignCreator: params.campaignCreator });

        vm.expectEmit({ emitter: address(factoryMerkleLT) });
        emit ISablierFactoryMerkleLT.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(vars.expectedMerkleCampaign),
            params: constructorParams,
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.leavesData.length,
            totalDuration: TOTAL_DURATION,
            minFeeUSD: vars.minFeeUSD,
            oracle: vars.oracle
        });

        merkleLT = factoryMerkleLT.createMerkleLT(constructorParams, vars.aggregateAmount, vars.leavesData.length);

        assertLt(0, address(merkleLT).code.length, "MerkleLT contract not created");
        assertEq(address(merkleLT), vars.expectedMerkleCampaign, "MerkleLT contract does not match computed address");

        // Cast the {MerkleLT} contract as {ISablierMerkleBase}
        merkleBase = merkleLT;

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        preClaim(params);

        uint256 expectedStreamId;
        uint256 initialRecipientTokenBalance = FORK_TOKEN.balanceOf(vars.leafToClaim.recipient);

        // It should emit {Claim} event based on the schedule end time.
        if (expectedStartTime + TOTAL_DURATION <= getBlockTimestamp()) {
            vm.expectEmit({ emitter: address(merkleLT) });
            emit ISablierMerkleLockup.Claim(vars.leafToClaim.index, vars.leafToClaim.recipient, vars.leafToClaim.amount);
            expectCallToTransfer({ token: FORK_TOKEN, to: vars.leafToClaim.recipient, value: vars.leafToClaim.amount });
        } else {
            expectedStreamId = lockup.nextStreamId();
            vm.expectEmit({ emitter: address(merkleLT) });
            emit ISablierMerkleLockup.Claim(
                vars.leafToClaim.index, vars.leafToClaim.recipient, vars.leafToClaim.amount, expectedStreamId
            );
        }

        expectCallToClaimWithData({
            merkleLockup: address(merkleLT),
            feeInWei: vars.minFeeWei,
            index: vars.leafToClaim.index,
            recipient: vars.leafToClaim.recipient,
            amount: vars.leafToClaim.amount,
            merkleProof: vars.merkleProof
        });

        // Claim the airdrop.
        merkleLT.claim{ value: vars.minFeeWei }({
            index: vars.leafToClaim.index,
            recipient: vars.leafToClaim.recipient,
            amount: vars.leafToClaim.amount,
            merkleProof: vars.merkleProof
        });

        // Assertions when schedule end time does not exceed the block time.
        if (expectedStartTime + TOTAL_DURATION <= getBlockTimestamp()) {
            assertEq(
                FORK_TOKEN.balanceOf(vars.leafToClaim.recipient),
                initialRecipientTokenBalance + vars.leafToClaim.amount,
                "recipient balance"
            );
        }
        // Assertions when schedule end time exceeds the block time.
        else {
            Lockup.CreateWithTimestamps memory expectedLockup = Lockup.CreateWithTimestamps({
                sender: params.campaignCreator,
                recipient: vars.leafToClaim.recipient,
                depositAmount: vars.leafToClaim.amount,
                token: FORK_TOKEN,
                cancelable: STREAM_CANCELABLE,
                transferable: STREAM_TRANSFERABLE,
                timestamps: Lockup.Timestamps({ start: expectedStartTime, end: expectedStartTime + TOTAL_DURATION }),
                shape: STREAM_SHAPE
            });

            // Assert that the stream has been created successfully.
            assertEq(lockup, expectedStreamId, expectedLockup);
            assertEq(lockup.getLockupModel(expectedStreamId), Lockup.Model.LOCKUP_TRANCHED);
            assertEq(
                lockup.getTranches(expectedStreamId),
                tranchesMerkleLT({ streamStartTime: expectedStartTime, totalAmount: vars.leafToClaim.amount })
            );

            uint256[] memory expectedClaimedStreamIds = new uint256[](1);
            expectedClaimedStreamIds[0] = expectedStreamId;
            assertEq(merkleLT.claimedStreams(vars.leafToClaim.recipient), expectedClaimedStreamIds, "claimed streams");
        }

        // Assert that the claim has been made.
        assertTrue(merkleLT.hasClaimed(vars.leafToClaim.index));

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
