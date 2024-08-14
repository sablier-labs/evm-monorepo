// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { Lockup, LockupTranched } from "src/core/types/DataTypes.sol";
import { Errors } from "src/periphery/libraries/Errors.sol";
import { MerkleLT } from "src/periphery/types/DataTypes.sol";

import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleLT_Integration_Shared_Test } from "../MerkleLT.t.sol";

contract Claim_MerkleLT_Integration_Test is Claim_Integration_Test, MerkleLT_Integration_Shared_Test {
    function setUp() public override(Claim_Integration_Test, MerkleLT_Integration_Shared_Test) {
        super.setUp();
    }

    modifier whenTotalPercentageNotOneHundred() {
        _;
    }

    function test_RevertWhen_TotalPercentageLessThanOneHundred() external whenTotalPercentageNotOneHundred {
        // Create a MerkleLT campaign with a total percentage less than 100.
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.05e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.2e18);

        merkleLT = merkleFactory.createMerkleLT(
            defaults.baseParams(),
            lockupTranched,
            defaults.CANCELABLE(),
            defaults.TRANSFERABLE(),
            tranchesWithPercentages,
            defaults.AGGREGATE_AMOUNT(),
            defaults.RECIPIENT_COUNT()
        );

        uint64 totalPercentage =
            tranchesWithPercentages[0].unlockPercentage.unwrap() + tranchesWithPercentages[1].unlockPercentage.unwrap();

        // Claim an airstream.
        bytes32[] memory merkleProof = defaults.index1Proof();

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleLT_TotalPercentageNotOneHundred.selector, totalPercentage)
        );

        merkleLT.claim({ index: 1, recipient: users.recipient1, amount: 10_000e18, merkleProof: merkleProof });
    }

    function test_RevertWhen_TotalPercentageGreaterThanOneHundred() external whenTotalPercentageNotOneHundred {
        // Create a MerkleLT campaign with a total percentage less than 100.
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.75e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.8e18);

        merkleLT = merkleFactory.createMerkleLT(
            defaults.baseParams(),
            lockupTranched,
            defaults.CANCELABLE(),
            defaults.TRANSFERABLE(),
            tranchesWithPercentages,
            defaults.AGGREGATE_AMOUNT(),
            defaults.RECIPIENT_COUNT()
        );

        uint64 totalPercentage =
            tranchesWithPercentages[0].unlockPercentage.unwrap() + tranchesWithPercentages[1].unlockPercentage.unwrap();

        // Claim an airstream.
        bytes32[] memory merkleProof = defaults.index1Proof();

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleLT_TotalPercentageNotOneHundred.selector, totalPercentage)
        );

        merkleLT.claim({ index: 1, recipient: users.recipient1, amount: 10_000e18, merkleProof: merkleProof });
    }

    modifier whenTotalPercentageOneHundred() {
        _;
    }

    modifier whenCalculatedAmountsSumEqualsClaimAmount() {
        _;
    }

    function test_Claim()
        external
        override
        whenTotalPercentageOneHundred
        givenCampaignNotExpired
        givenNotClaimed
        givenIncludedInMerkleTree
        whenCalculatedAmountsSumEqualsClaimAmount
    {
        uint256 expectedStreamId = lockupTranched.nextStreamId();
        vm.expectEmit({ emitter: address(merkleLT) });
        emit Claim(defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), expectedStreamId);

        claim();
        LockupTranched.StreamLT memory actualStream = lockupTranched.getStream(expectedStreamId);
        LockupTranched.StreamLT memory expectedStream = LockupTranched.StreamLT({
            amounts: Lockup.Amounts({ deposited: defaults.CLAIM_AMOUNT(), refunded: 0, withdrawn: 0 }),
            asset: dai,
            endTime: getBlockTimestamp() + defaults.TOTAL_DURATION(),
            isCancelable: defaults.CANCELABLE(),
            isDepleted: false,
            isStream: true,
            isTransferable: defaults.TRANSFERABLE(),
            recipient: users.recipient1,
            sender: users.admin,
            startTime: getBlockTimestamp(),
            tranches: defaults.tranchesMerkleLT(),
            wasCanceled: false
        });

        assertEq(actualStream, expectedStream);
        assertTrue(merkleLT.hasClaimed(defaults.INDEX1()), "not claimed");
    }
}
