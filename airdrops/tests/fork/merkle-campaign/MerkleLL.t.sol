// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import { Lockup, LockupLinear } from "@sablier/lockup/src/types/DataTypes.sol";

import { ISablierMerkleFactoryLL } from "src/interfaces/ISablierMerkleFactoryLL.sol";
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

        // Cast the {merkleFactoryLL} contract as {ISablierMerkleFactoryBase}
        merkleFactoryBase = merkleFactoryLL;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST-FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testForkFuzz_MerkleLL(Params memory params, uint40 startTime) external {
        /*//////////////////////////////////////////////////////////////////////////
                                          CREATE
        //////////////////////////////////////////////////////////////////////////*/

        uint40 expectedStartTime;

        // If the start time is not zero, bound it to a reasonable range so that vesting end time can be in the past,
        // present and future.
        if (startTime != 0) {
            startTime =
                boundUint40(startTime, getBlockTimestamp() - TOTAL_DURATION - 10 days, getBlockTimestamp() + 2 days);
            expectedStartTime = startTime;
        } else {
            expectedStartTime = getBlockTimestamp();
        }

        preCreateCampaign(params);

        vars.expectedMerkleCampaign = computeMerkleLLAddress({
            campaignCreator: params.campaignOwner,
            campaignOwner: params.campaignOwner,
            expiration: params.expiration,
            merkleRoot: vars.merkleRoot,
            startTime: startTime,
            tokenAddress: FORK_TOKEN
        });

        MerkleLL.ConstructorParams memory constructorParams = merkleLLConstructorParams({
            campaignOwner: params.campaignOwner,
            expiration: params.expiration,
            lockupAddress: lockup,
            merkleRoot: vars.merkleRoot,
            startTime: startTime,
            tokenAddress: FORK_TOKEN
        });

        vm.expectEmit({ emitter: address(merkleFactoryLL) });
        emit ISablierMerkleFactoryLL.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(vars.expectedMerkleCampaign),
            params: constructorParams,
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount,
            fee: vars.minimumFee,
            oracle: vars.oracle
        });

        merkleLL = merkleFactoryLL.createMerkleLL(constructorParams, vars.aggregateAmount, vars.recipientCount);

        assertGt(address(merkleLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(merkleLL), vars.expectedMerkleCampaign, "MerkleLL contract does not match computed address");

        // Cast the {MerkleLL} contract as {ISablierMerkleBase}
        merkleBase = merkleLL;

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        preClaim(params);

        uint256 expectedStreamId;
        uint256 initialRecipientTokenBalance = FORK_TOKEN.balanceOf(vars.recipientToClaim);

        // It should emit {Claim} event based on the vesting end time.
        if (expectedStartTime + TOTAL_DURATION <= getBlockTimestamp()) {
            vm.expectEmit({ emitter: address(merkleLL) });
            emit ISablierMerkleLockup.Claim(vars.indexToClaim, vars.recipientToClaim, vars.amountToClaim);
            expectCallToTransfer({ token: FORK_TOKEN, to: vars.recipientToClaim, value: vars.amountToClaim });
        } else {
            expectedStreamId = lockup.nextStreamId();
            vm.expectEmit({ emitter: address(merkleLL) });
            emit ISablierMerkleLockup.Claim(
                vars.indexToClaim, vars.recipientToClaim, vars.amountToClaim, expectedStreamId
            );
            expectCallToTransferFrom({
                token: FORK_TOKEN,
                from: address(merkleLL),
                to: address(lockup),
                value: vars.amountToClaim
            });
        }

        expectCallToClaimWithData({
            merkleLockup: address(merkleLL),
            feeInWei: vars.minimumFeeInWei,
            index: vars.indexToClaim,
            recipient: vars.recipientToClaim,
            amount: vars.amountToClaim,
            merkleProof: vars.merkleProof
        });

        // Claim the airdrop.
        merkleLL.claim{ value: vars.minimumFeeInWei }({
            index: vars.indexToClaim,
            recipient: vars.recipientToClaim,
            amount: vars.amountToClaim,
            merkleProof: vars.merkleProof
        });

        // Assertions when vesting end time does not exceed the block time.
        if (expectedStartTime + TOTAL_DURATION <= getBlockTimestamp()) {
            assertEq(
                FORK_TOKEN.balanceOf(vars.recipientToClaim),
                initialRecipientTokenBalance + vars.amountToClaim,
                "recipient token balance"
            );
        }
        // Assertions when vesting end time exceeds the block time.
        else {
            LockupLinear.UnlockAmounts memory expectedUnlockAmounts = LockupLinear.UnlockAmounts({
                start: ud60x18(vars.amountToClaim).mul(START_PERCENTAGE.intoUD60x18()).intoUint128(),
                cliff: ud60x18(vars.amountToClaim).mul(CLIFF_PERCENTAGE.intoUD60x18()).intoUint128()
            });

            Lockup.CreateWithTimestamps memory expectedLockup = Lockup.CreateWithTimestamps({
                sender: params.campaignOwner,
                recipient: vars.recipientToClaim,
                depositAmount: vars.amountToClaim,
                token: FORK_TOKEN,
                cancelable: CANCELABLE,
                transferable: TRANSFERABLE,
                timestamps: Lockup.Timestamps({ start: expectedStartTime, end: expectedStartTime + TOTAL_DURATION }),
                shape: SHAPE
            });

            // Assert that the stream has been created successfully.
            assertEq(lockup, expectedStreamId, expectedLockup);
            assertEq(lockup.getCliffTime(expectedStreamId), expectedStartTime + CLIFF_DURATION, "cliff time");
            assertEq(lockup.getLockupModel(expectedStreamId), Lockup.Model.LOCKUP_LINEAR);
            assertEq(lockup.getUnlockAmounts(expectedStreamId), expectedUnlockAmounts);

            uint256[] memory expectedClaimedStreamIds = new uint256[](1);
            expectedClaimedStreamIds[0] = expectedStreamId;
            assertEq(merkleLL.claimedStreams(vars.recipientToClaim), expectedClaimedStreamIds, "claimed streams");
        }

        // Assert that the claim has been made.
        assertTrue(merkleLL.hasClaimed(vars.indexToClaim));

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
