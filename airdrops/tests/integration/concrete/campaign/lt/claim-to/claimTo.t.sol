// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { Lockup } from "@sablier/lockup/src/types/DataTypes.sol";

import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { ClaimTo_Integration_Test } from "../../shared/claim-to/claimTo.t.sol";
import { MerkleLT_Integration_Shared_Test } from "../MerkleLT.t.sol";

contract ClaimTo_MerkleLT_Integration_Test is ClaimTo_Integration_Test, MerkleLT_Integration_Shared_Test {
    function setUp() public virtual override(MerkleLT_Integration_Shared_Test, ClaimTo_Integration_Test) {
        MerkleLT_Integration_Shared_Test.setUp();
        ClaimTo_Integration_Test.setUp();
    }

    function test_WhenVestingEndTimeNotExceedClaimTime() external whenMerkleProofValid {
        // Forward in time to the end of the vesting period.
        vm.warp({ newTimestamp: VESTING_END_TIME });

        uint256 expectedEveBalance = dai.balanceOf(users.eve) + CLAIM_AMOUNT;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleLT) });
        emit ISablierMerkleLockup.Claim(getIndexInMerkleTree(), users.recipient, CLAIM_AMOUNT, users.eve);

        expectCallToTransfer({ to: users.eve, value: CLAIM_AMOUNT });
        expectCallToClaimToWithMsgValue(address(merkleLT), MIN_FEE_WEI);

        claimTo();

        // It should transfer the tokens to Eve.
        assertEq(dai.balanceOf(users.eve), expectedEveBalance, "eve balance");
    }

    function test_RevertWhen_TotalPercentageLessThan100()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentageNot100
    {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();

        // Create a MerkleLT campaign with a total percentage less than 100.
        params.tranchesWithPercentages[0].unlockPercentage = ud2x18(0.05e18);
        params.tranchesWithPercentages[1].unlockPercentage = ud2x18(0.2e18);

        // Create the MerkleLT campaign and cast it as {ISablierMerkleBase}.
        merkleLT = factoryMerkleLT.createMerkleLT(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
        merkleBase = merkleLT;

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleLT_TotalPercentageNotOneHundred.selector, 0.25e18));

        claimTo();
    }

    function test_RevertWhen_TotalPercentageGreaterThan100()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentageNot100
    {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();

        params.tranchesWithPercentages[0].unlockPercentage = ud2x18(0.75e18);
        params.tranchesWithPercentages[1].unlockPercentage = ud2x18(0.8e18);

        // Create the MerkleLT campaign and cast it as {ISablierMerkleBase}.
        merkleLT = factoryMerkleLT.createMerkleLT(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
        merkleBase = merkleLT;

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleLT_TotalPercentageNotOneHundred.selector, 1.55e18));

        claimTo();
    }

    function test_WhenVestingStartTimeZero()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentage100
    {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();
        params.vestingStartTime = 0;

        // Create the MerkleLT campaign and cast it as {ISablierMerkleBase}.
        merkleLT = factoryMerkleLT.createMerkleLT(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
        merkleBase = merkleLT;

        // It should create a stream with `block.timestamp` as stream start time.
        // It should create a stream with Eve as recipient.
        _test_ClaimTo({ streamStartTime: getBlockTimestamp() });
    }

    function test_WhenVestingStartTimeNotZero()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentage100
    {
        // It should create a ranged stream with provided start time.
        // It should create a stream with Eve as recipient.
        _test_ClaimTo({ streamStartTime: VESTING_START_TIME });
    }

    /// @dev Helper function to test claim.
    function _test_ClaimTo(uint40 streamStartTime) private {
        deal({ token: address(dai), to: address(merkleLT), give: AGGREGATE_AMOUNT });

        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(factoryMerkleLT).balance;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleLT) });
        emit ISablierMerkleLockup.Claim(
            getIndexInMerkleTree(), users.recipient, CLAIM_AMOUNT, expectedStreamId, users.eve
        );

        expectCallToTransferFrom({ from: address(merkleLT), to: address(lockup), value: CLAIM_AMOUNT });
        expectCallToClaimToWithMsgValue(address(merkleLT), MIN_FEE_WEI);

        // Claim the airstream.
        claimTo();

        // Assert that the stream has been created successfully.
        assertEq(lockup.getDepositedAmount(expectedStreamId), CLAIM_AMOUNT, "depositedAmount");
        assertEq(lockup.getEndTime(expectedStreamId), streamStartTime + VESTING_TOTAL_DURATION, "stream end time");
        assertEq(lockup.getRecipient(expectedStreamId), users.eve, "eve");
        assertEq(lockup.getSender(expectedStreamId), users.campaignCreator, "sender");
        assertEq(lockup.getStartTime(expectedStreamId), streamStartTime, "stream start time");
        // It should create a stream with `VESTING_START_TIME` as start time.
        assertEq(
            lockup.getTranches(expectedStreamId),
            tranchesMerkleLT({ streamStartTime: streamStartTime, totalAmount: CLAIM_AMOUNT })
        );
        assertEq(lockup.getUnderlyingToken(expectedStreamId), dai, "token");
        assertEq(lockup.isCancelable(expectedStreamId), STREAM_CANCELABLE, "is cancelable");
        assertEq(lockup.isDepleted(expectedStreamId), false, "is depleted");
        assertEq(lockup.isStream(expectedStreamId), true, "is stream");
        assertEq(lockup.isTransferable(expectedStreamId), STREAM_TRANSFERABLE, "is transferable");
        assertEq(lockup.wasCanceled(expectedStreamId), false, "was canceled");

        assertTrue(merkleLT.hasClaimed(getIndexInMerkleTree()), "not claimed");

        // It should create the stream with the correct Lockup model.
        assertEq(lockup.getLockupModel(expectedStreamId), Lockup.Model.LOCKUP_TRANCHED);

        uint256[] memory expectedClaimedStreamIds = new uint256[](1);
        expectedClaimedStreamIds[0] = expectedStreamId;
        assertEq(merkleLT.claimedStreams(users.recipient), expectedClaimedStreamIds, "claimed streams");

        assertEq(address(factoryMerkleLT).balance, previousFeeAccrued + MIN_FEE_WEI, "fee collected");
    }
}
