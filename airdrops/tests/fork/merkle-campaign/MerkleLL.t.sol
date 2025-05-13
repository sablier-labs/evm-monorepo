// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import { Lockup, LockupLinear } from "@sablier/lockup/src/types/DataTypes.sol";

import { ISablierFactoryMerkleLL } from "src/interfaces/ISablierFactoryMerkleLL.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Fork_Test } from "./../Fork.t.sol";
import { MerkleBase_Fork_Test } from "./MerkleBase.t.sol";

abstract contract MerkleLL_Fork_Test is MerkleBase_Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 tokenAddress) MerkleBase_Fork_Test(tokenAddress) { }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fork_Test.setUp();

        // Cast the {FactoryMerkleLL} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleLL;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST-FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testForkFuzz_MerkleLL(Params memory params, uint40 startTime) external {
        /*//////////////////////////////////////////////////////////////////////////
                                          CREATE
        //////////////////////////////////////////////////////////////////////////*/

        uint40 expectedStartTime;

        // If the start time is not zero, bound it to a reasonable range so that end time can be in the past, present
        // and future.
        if (startTime != 0) {
            startTime = boundUint40(
                startTime, getBlockTimestamp() - VESTING_TOTAL_DURATION - 10 days, getBlockTimestamp() + 2 days
            );
            expectedStartTime = startTime;
        } else {
            expectedStartTime = getBlockTimestamp();
        }

        preCreateCampaign(params);

        MerkleLL.ConstructorParams memory constructorParams = merkleLLConstructorParams({
            campaignCreator: params.campaignCreator,
            expiration: params.expiration,
            lockupAddress: lockup,
            merkleRoot: vars.merkleRoot,
            startTime: startTime,
            tokenAddress: FORK_TOKEN
        });

        vars.expectedMerkleCampaign =
            computeMerkleLLAddress({ params: constructorParams, campaignCreator: params.campaignCreator });

        vm.expectEmit({ emitter: address(factoryMerkleLL) });
        emit ISablierFactoryMerkleLL.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(vars.expectedMerkleCampaign),
            params: constructorParams,
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.leavesData.length,
            minFeeUSD: vars.minFeeUSD,
            oracle: vars.oracle
        });

        merkleLL = factoryMerkleLL.createMerkleLL(constructorParams, vars.aggregateAmount, vars.leavesData.length);

        assertLt(0, address(merkleLL).code.length, "MerkleLL contract not created");
        assertEq(address(merkleLL), vars.expectedMerkleCampaign, "MerkleLL contract does not match computed address");

        // Cast the {MerkleLL} contract as {ISablierMerkleBase}
        merkleBase = merkleLL;

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        preClaim(params);

        uint256 expectedStreamId;
        uint256 initialRecipientTokenBalance = FORK_TOKEN.balanceOf(vars.leafToClaim.recipient);

        // It should emit {Claim} event based on the end time.
        if (expectedStartTime + VESTING_TOTAL_DURATION <= getBlockTimestamp()) {
            vm.expectEmit({ emitter: address(merkleLL) });
            emit ISablierMerkleLockup.Claim({
                index: vars.leafToClaim.index,
                recipient: vars.leafToClaim.recipient,
                amount: vars.leafToClaim.amount,
                to: vars.leafToClaim.recipient
            });
            expectCallToTransfer({ token: FORK_TOKEN, to: vars.leafToClaim.recipient, value: vars.leafToClaim.amount });
        } else {
            expectedStreamId = lockup.nextStreamId();
            vm.expectEmit({ emitter: address(merkleLL) });
            emit ISablierMerkleLockup.Claim({
                index: vars.leafToClaim.index,
                recipient: vars.leafToClaim.recipient,
                amount: vars.leafToClaim.amount,
                streamId: expectedStreamId,
                to: vars.leafToClaim.recipient
            });
            expectCallToTransferFrom({
                token: FORK_TOKEN,
                from: address(merkleLL),
                to: address(lockup),
                value: vars.leafToClaim.amount
            });
        }

        expectCallToClaimWithData({
            merkleLockup: address(merkleLL),
            feeInWei: vars.minFeeWei,
            index: vars.leafToClaim.index,
            recipient: vars.leafToClaim.recipient,
            amount: vars.leafToClaim.amount,
            merkleProof: vars.merkleProof
        });

        // Claim the airdrop.
        merkleLL.claim{ value: vars.minFeeWei }({
            index: vars.leafToClaim.index,
            recipient: vars.leafToClaim.recipient,
            amount: vars.leafToClaim.amount,
            merkleProof: vars.merkleProof
        });

        // Assertions when end time does not exceed the block time.
        if (expectedStartTime + VESTING_TOTAL_DURATION <= getBlockTimestamp()) {
            assertEq(
                FORK_TOKEN.balanceOf(vars.leafToClaim.recipient),
                initialRecipientTokenBalance + vars.leafToClaim.amount,
                "recipient token balance"
            );
        }
        // Assertions when end time exceeds the block time.
        else {
            LockupLinear.UnlockAmounts memory expectedUnlockAmounts = LockupLinear.UnlockAmounts({
                start: ud60x18(vars.leafToClaim.amount).mul(VESTING_START_UNLOCK_PERCENTAGE).intoUint128(),
                cliff: ud60x18(vars.leafToClaim.amount).mul(VESTING_CLIFF_UNLOCK_PERCENTAGE).intoUint128()
            });

            Lockup.CreateWithTimestamps memory expectedLockup = Lockup.CreateWithTimestamps({
                sender: params.campaignCreator,
                recipient: vars.leafToClaim.recipient,
                depositAmount: vars.leafToClaim.amount,
                token: FORK_TOKEN,
                cancelable: STREAM_CANCELABLE,
                transferable: STREAM_TRANSFERABLE,
                timestamps: Lockup.Timestamps({ start: expectedStartTime, end: expectedStartTime + VESTING_TOTAL_DURATION }),
                shape: STREAM_SHAPE
            });

            // Assert that the stream has been created successfully.
            assertEq(lockup, expectedStreamId, expectedLockup);
            assertEq(lockup.getCliffTime(expectedStreamId), expectedStartTime + VESTING_CLIFF_DURATION, "cliff time");
            assertEq(lockup.getLockupModel(expectedStreamId), Lockup.Model.LOCKUP_LINEAR);
            assertEq(lockup.getUnlockAmounts(expectedStreamId), expectedUnlockAmounts);

            uint256[] memory expectedClaimedStreamIds = new uint256[](1);
            expectedClaimedStreamIds[0] = expectedStreamId;
            assertEq(merkleLL.claimedStreams(vars.leafToClaim.recipient), expectedClaimedStreamIds, "claimed streams");
        }

        // Assert that the claim has been made.
        assertTrue(merkleLL.hasClaimed(vars.leafToClaim.index));

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
