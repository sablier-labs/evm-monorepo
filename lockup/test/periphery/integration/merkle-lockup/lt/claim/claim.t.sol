// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { Lockup, LockupTranched } from "src/core/types/DataTypes.sol";
import { ISablierMerkleLT } from "src/periphery/interfaces/ISablierMerkleLT.sol";
import { Errors } from "src/periphery/libraries/Errors.sol";
import { MerkleLockup, MerkleLT } from "src/periphery/types/DataTypes.sol";

import { MerkleBuilder } from "test/utils/MerkleBuilder.sol";
import { Merkle } from "test/utils/Murky.sol";

import { MerkleLockup_Integration_Test } from "../../MerkleLockup.t.sol";

contract Claim_Integration_Test is Merkle, MerkleLockup_Integration_Test {
    using MerkleBuilder for uint256[];

    function setUp() public virtual override {
        MerkleLockup_Integration_Test.setUp();
    }

    modifier whenTotalPercentageNotOneHundred() {
        _;
    }

    function test_RevertWhen_TotalPercentageLessThanOneHundred() external whenTotalPercentageNotOneHundred {
        // Create a MerkleLT campaign with a total percentage less than 100.
        MerkleLockup.ConstructorParams memory baseParams = defaults.baseParams();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.05e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.2e18);

        uint64 totalPercentage =
            tranchesWithPercentages[0].unlockPercentage.unwrap() + tranchesWithPercentages[1].unlockPercentage.unwrap();

        merkleLT = merkleLockupFactory.createMerkleLT(
            baseParams, lockupTranched, tranchesWithPercentages, aggregateAmount, recipientCount
        );

        // Claim an airstream.
        bytes32[] memory merkleProof = defaults.index1Proof();

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleLT_TotalPercentageNotOneHundred.selector, totalPercentage)
        );

        merkleLT.claim({ index: 1, recipient: users.recipient1, amount: 1, merkleProof: merkleProof });
    }

    function test_RevertWhen_TotalPercentageGreaterThanOneHundred() external whenTotalPercentageNotOneHundred {
        // Create a MerkleLT campaign with a total percentage less than 100.
        MerkleLockup.ConstructorParams memory baseParams = defaults.baseParams();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.75e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.8e18);

        uint64 totalPercentage =
            tranchesWithPercentages[0].unlockPercentage.unwrap() + tranchesWithPercentages[1].unlockPercentage.unwrap();

        merkleLT = merkleLockupFactory.createMerkleLT(
            baseParams, lockupTranched, tranchesWithPercentages, aggregateAmount, recipientCount
        );

        // Claim an airstream.
        bytes32[] memory merkleProof = defaults.index1Proof();

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleLT_TotalPercentageNotOneHundred.selector, totalPercentage)
        );

        merkleLT.claim({ index: 1, recipient: users.recipient1, amount: 1, merkleProof: merkleProof });
    }

    modifier whenTotalPercentageOneHundred() {
        _;
    }

    function test_RevertGiven_CampaignExpired() external whenTotalPercentageOneHundred {
        uint40 expiration = defaults.EXPIRATION();
        uint256 warpTime = expiration + 1 seconds;
        bytes32[] memory merkleProof;
        vm.warp({ newTimestamp: warpTime });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleLockup_CampaignExpired.selector, warpTime, expiration)
        );
        merkleLT.claim({ index: 1, recipient: users.recipient1, amount: 1, merkleProof: merkleProof });
    }

    modifier givenCampaignNotExpired() {
        _;
    }

    function test_RevertGiven_AlreadyClaimed() external whenTotalPercentageOneHundred givenCampaignNotExpired {
        claimLT();
        uint256 index1 = defaults.INDEX1();
        uint128 amount = defaults.CLAIM_AMOUNT();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleLockup_StreamClaimed.selector, index1));
        merkleLT.claim(index1, users.recipient1, amount, merkleProof);
    }

    modifier givenNotClaimed() {
        _;
    }

    modifier givenNotIncludedInMerkleTree() {
        _;
    }

    function test_RevertWhen_InvalidIndex()
        external
        whenTotalPercentageOneHundred
        givenCampaignNotExpired
        givenNotClaimed
        givenNotIncludedInMerkleTree
    {
        uint256 invalidIndex = 1337;
        uint128 amount = defaults.CLAIM_AMOUNT();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleLockup_InvalidProof.selector));
        merkleLT.claim(invalidIndex, users.recipient1, amount, merkleProof);
    }

    function test_RevertWhen_InvalidRecipient()
        external
        whenTotalPercentageOneHundred
        givenCampaignNotExpired
        givenNotClaimed
        givenNotIncludedInMerkleTree
    {
        uint256 index1 = defaults.INDEX1();
        address invalidRecipient = address(1337);
        uint128 amount = defaults.CLAIM_AMOUNT();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleLockup_InvalidProof.selector));
        merkleLT.claim(index1, invalidRecipient, amount, merkleProof);
    }

    function test_RevertWhen_InvalidAmount()
        external
        whenTotalPercentageOneHundred
        givenCampaignNotExpired
        givenNotClaimed
        givenNotIncludedInMerkleTree
    {
        uint256 index1 = defaults.INDEX1();
        uint128 invalidAmount = 1337;
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleLockup_InvalidProof.selector));
        merkleLT.claim(index1, users.recipient1, invalidAmount, merkleProof);
    }

    function test_RevertWhen_InvalidMerkleProof()
        external
        whenTotalPercentageOneHundred
        givenCampaignNotExpired
        givenNotClaimed
        givenNotIncludedInMerkleTree
    {
        uint256 index1 = defaults.INDEX1();
        uint128 amount = defaults.CLAIM_AMOUNT();
        bytes32[] memory invalidMerkleProof = defaults.index2Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleLockup_InvalidProof.selector));
        merkleLT.claim(index1, users.recipient1, amount, invalidMerkleProof);
    }

    modifier givenIncludedInMerkleTree() {
        _;
    }

    /// @dev Needed this variable in storage due to how the imported libraries work.
    uint256[] public leaves = new uint256[](4); // same number of recipients as in Defaults

    function test_Claim_CalculatedAmountsSumNotEqualClaimAmount()
        external
        whenTotalPercentageOneHundred
        givenCampaignNotExpired
        givenNotClaimed
        givenIncludedInMerkleTree
    {
        // Declare a claim amount that will cause a rounding error.
        uint128 claimAmount = defaults.CLAIM_AMOUNT() + 1;

        // Compute the test Merkle tree.
        leaves = defaults.getLeaves();
        uint256 leaf = MerkleBuilder.computeLeaf(defaults.INDEX1(), users.recipient1, claimAmount);
        leaves[0] = leaf;
        MerkleBuilder.sortLeaves(leaves);

        // Compute the test Merkle proof.
        uint256 pos = Arrays.findUpperBound(leaves, leaf);
        bytes32[] memory proof = getProof(leaves.toBytes32(), pos);

        /// Declare the constructor params.
        MerkleLockup.ConstructorParams memory baseParams = defaults.baseParams();
        baseParams.merkleRoot = getRoot(leaves.toBytes32());

        // Deploy a test MerkleLT contract.
        ISablierMerkleLT testMerkleLT = merkleLockupFactory.createMerkleLT(
            baseParams,
            lockupTranched,
            defaults.tranchesWithPercentages(),
            defaults.AGGREGATE_AMOUNT(),
            defaults.RECIPIENT_COUNT()
        );

        // Fund the MerkleLT contract.
        deal({ token: address(dai), to: address(testMerkleLT), give: defaults.AGGREGATE_AMOUNT() });

        uint256 expectedStreamId = lockupTranched.nextStreamId();
        vm.expectEmit({ emitter: address(testMerkleLT) });
        emit Claim(defaults.INDEX1(), users.recipient1, claimAmount, expectedStreamId);

        uint256 actualStreamId = testMerkleLT.claim(defaults.INDEX1(), users.recipient1, claimAmount, proof);
        LockupTranched.StreamLT memory actualStream = lockupTranched.getStream(actualStreamId);
        LockupTranched.StreamLT memory expectedStream = LockupTranched.StreamLT({
            amounts: Lockup.Amounts({ deposited: claimAmount, refunded: 0, withdrawn: 0 }),
            asset: dai,
            endTime: getBlockTimestamp() + defaults.TOTAL_DURATION(),
            isCancelable: defaults.CANCELABLE(),
            isDepleted: false,
            isStream: true,
            isTransferable: defaults.TRANSFERABLE(),
            recipient: users.recipient1,
            sender: users.admin,
            startTime: getBlockTimestamp(),
            tranches: defaults.tranchesMerkleLockup(claimAmount),
            wasCanceled: false
        });

        assertTrue(testMerkleLT.hasClaimed(defaults.INDEX1()), "not claimed");
        assertEq(actualStreamId, expectedStreamId, "invalid stream id");
        assertEq(actualStream, expectedStream);
    }

    modifier whenCalculatedAmountsSumEqualsClaimAmount() {
        _;
    }

    function test_Claim()
        external
        whenTotalPercentageOneHundred
        givenCampaignNotExpired
        givenNotClaimed
        givenIncludedInMerkleTree
        whenCalculatedAmountsSumEqualsClaimAmount
    {
        uint256 expectedStreamId = lockupTranched.nextStreamId();
        vm.expectEmit({ emitter: address(merkleLT) });
        emit Claim(defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), expectedStreamId);

        uint256 actualStreamId = claimLT();
        LockupTranched.StreamLT memory actualStream = lockupTranched.getStream(actualStreamId);
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
            tranches: defaults.tranchesMerkleLockup(),
            wasCanceled: false
        });

        assertTrue(merkleLT.hasClaimed(defaults.INDEX1()), "not claimed");
        assertEq(actualStreamId, expectedStreamId, "invalid stream id");
        assertEq(actualStream, expectedStream);
    }
}
