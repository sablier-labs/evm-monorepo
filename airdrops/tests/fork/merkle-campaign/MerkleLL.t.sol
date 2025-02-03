// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import { Lockup, LockupLinear } from "@sablier/lockup/src/types/DataTypes.sol";

import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleBase, ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { MerkleBase } from "src/types/DataTypes.sol";

import { MerkleBuilder } from "./../../utils/MerkleBuilder.sol";
import { Fork_Test } from "./../Fork.t.sol";

abstract contract MerkleLL_Fork_Test is Fork_Test {
    using MerkleBuilder for uint256[];

    constructor(IERC20 token_) Fork_Test(token_) { }

    /// @dev Encapsulates the data needed to compute a Merkle tree leaf.
    struct LeafData {
        uint256 index;
        uint256 recipientSeed;
        uint128 amount;
    }

    struct Params {
        address campaignOwner;
        uint40 expiration;
        LeafData[] leafData;
        uint256 posBeforeSort;
    }

    struct Vars {
        uint256 aggregateAmount;
        uint128[] amounts;
        MerkleBase.ConstructorParams baseParams;
        uint128 clawbackAmount;
        address expectedLL;
        uint256 expectedStreamId;
        uint256[] indexes;
        uint256 leafPos;
        uint256 leafToClaim;
        ISablierMerkleLL merkleLL;
        bytes32[] merkleProof;
        bytes32 merkleRoot;
        address[] recipients;
        uint256 recipientCount;
        LockupLinear.UnlockAmounts expectedUnlockAmounts;
    }

    // We need the leaves as a storage variable so that we can use OpenZeppelin's {Arrays.findUpperBound}.
    uint256[] public leaves;

    function testForkFuzz_MerkleLL(Params memory params) external {
        vm.assume(params.campaignOwner != address(0));
        vm.assume(params.leafData.length > 0);
        assumeNoBlacklisted({ token: address(FORK_TOKEN), addr: params.campaignOwner });
        params.posBeforeSort = _bound(params.posBeforeSort, 0, params.leafData.length - 1);

        // The expiration must be either zero or greater than the block timestamp.
        if (params.expiration != 0) {
            params.expiration = boundUint40(params.expiration, getBlockTimestamp() + 1 seconds, MAX_UNIX_TIMESTAMP);
        }

        /*//////////////////////////////////////////////////////////////////////////
                                          CREATE
        //////////////////////////////////////////////////////////////////////////*/

        Vars memory vars;
        vars.recipientCount = params.leafData.length;
        vars.amounts = new uint128[](vars.recipientCount);
        vars.indexes = new uint256[](vars.recipientCount);
        vars.recipients = new address[](vars.recipientCount);
        for (uint256 i = 0; i < vars.recipientCount; ++i) {
            vars.indexes[i] = params.leafData[i].index;

            // Bound each leaf amount so that `aggregateAmount` does not overflow.
            vars.amounts[i] = boundUint128(params.leafData[i].amount, 1, uint128(MAX_UINT128 / vars.recipientCount - 1));
            vars.aggregateAmount += vars.amounts[i];

            // Avoid zero recipient addresses.
            uint256 boundedRecipientSeed = _bound(params.leafData[i].recipientSeed, 1, type(uint160).max);
            // Avoid recipient to be the protocol admin.
            vars.recipients[i] = address(uint160(boundedRecipientSeed)) != factoryAdmin
                ? address(uint160(boundedRecipientSeed))
                : address(uint160(boundedRecipientSeed) + 1);
        }

        leaves = new uint256[](vars.recipientCount);
        leaves = MerkleBuilder.computeLeaves(vars.indexes, vars.recipients, vars.amounts);

        // Sort the leaves in ascending order to match the production environment.
        MerkleBuilder.sortLeaves(leaves);

        // Compute the Merkle root.
        if (leaves.length == 1) {
            // If there is only one leaf, the Merkle root is the hash of the leaf itself.
            vars.merkleRoot = bytes32(leaves[0]);
        } else {
            vars.merkleRoot = getRoot(leaves.toBytes32());
        }

        // Make the campaign owner as the caller.
        resetPrank({ msgSender: params.campaignOwner });

        vars.expectedLL = computeMerkleLLAddress(
            params.campaignOwner, params.campaignOwner, FORK_TOKEN, vars.merkleRoot, params.expiration
        );

        vars.baseParams = defaults.baseParams({
            campaignOwner: params.campaignOwner,
            token_: FORK_TOKEN,
            expiration: params.expiration,
            merkleRoot: vars.merkleRoot
        });

        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(vars.expectedLL),
            baseParams: vars.baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount,
            fee: defaults.FEE()
        });

        vars.merkleLL = merkleFactory.createMerkleLL({
            baseParams: vars.baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount
        });

        // Fund the MerkleLL contract.
        deal({ token: address(FORK_TOKEN), to: address(vars.merkleLL), give: vars.aggregateAmount });

        assertGt(address(vars.merkleLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(vars.merkleLL), vars.expectedLL, "MerkleLL contract does not match computed address");

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        // Make the recipient as the caller.
        resetPrank({ msgSender: vars.recipients[params.posBeforeSort] });
        vm.deal(vars.recipients[params.posBeforeSort], 1 ether);

        uint256 initialAdminBalance = factoryAdmin.balance;

        assertFalse(vars.merkleLL.hasClaimed(vars.indexes[params.posBeforeSort]));

        vars.leafToClaim = MerkleBuilder.computeLeaf(
            vars.indexes[params.posBeforeSort],
            vars.recipients[params.posBeforeSort],
            vars.amounts[params.posBeforeSort]
        );
        vars.leafPos = Arrays.findUpperBound(leaves, vars.leafToClaim);

        vars.expectedStreamId = lockup.nextStreamId();

        vm.expectEmit({ emitter: address(vars.merkleLL) });
        emit ISablierMerkleLL.Claim(
            vars.indexes[params.posBeforeSort],
            vars.recipients[params.posBeforeSort],
            vars.amounts[params.posBeforeSort],
            vars.expectedStreamId
        );

        // Compute the Merkle proof.
        if (leaves.length == 1) {
            // If there is only one leaf, the Merkle proof should be an empty array as no proof is needed because the
            // leaf is the root.
        } else {
            vars.merkleProof = getProof(leaves.toBytes32(), vars.leafPos);
        }

        expectCallToClaimWithData({
            merkleLockup: address(vars.merkleLL),
            fee: defaults.FEE(),
            index: vars.indexes[params.posBeforeSort],
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        vars.merkleLL.claim{ value: defaults.FEE() }({
            index: vars.indexes[params.posBeforeSort],
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        vars.expectedUnlockAmounts.start =
            ud60x18(vars.amounts[params.posBeforeSort]).mul(defaults.START_PERCENTAGE().intoUD60x18()).intoUint128();
        vars.expectedUnlockAmounts.cliff =
            ud60x18(vars.amounts[params.posBeforeSort]).mul(defaults.CLIFF_PERCENTAGE().intoUD60x18()).intoUint128();

        // Assert that the stream has been created successfully.
        assertEq(
            lockup.getCliffTime(vars.expectedStreamId), getBlockTimestamp() + defaults.CLIFF_DURATION(), "cliff time"
        );
        assertEq(
            lockup.getDepositedAmount(vars.expectedStreamId), vars.amounts[params.posBeforeSort], "deposited amount"
        );
        assertEq(lockup.getEndTime(vars.expectedStreamId), getBlockTimestamp() + defaults.TOTAL_DURATION(), "end time");
        assertEq(lockup.getLockupModel(vars.expectedStreamId), Lockup.Model.LOCKUP_LINEAR);
        assertEq(lockup.getRecipient(vars.expectedStreamId), vars.recipients[params.posBeforeSort], "recipient");
        assertEq(lockup.getRefundedAmount(vars.expectedStreamId), 0, "refunded amount");
        assertEq(lockup.getSender(vars.expectedStreamId), params.campaignOwner, "sender");
        assertEq(lockup.getStartTime(vars.expectedStreamId), getBlockTimestamp(), "start time");
        assertEq(lockup.getUnderlyingToken(vars.expectedStreamId), FORK_TOKEN, "token");
        assertEq(
            lockup.getUnlockAmounts(vars.expectedStreamId).cliff,
            vars.expectedUnlockAmounts.cliff,
            "unlock amounts cliff"
        );
        assertEq(
            lockup.getUnlockAmounts(vars.expectedStreamId).start,
            vars.expectedUnlockAmounts.start,
            "unlock amounts start"
        );
        assertEq(lockup.getWithdrawnAmount(vars.expectedStreamId), 0, "withdrawn amount");
        assertEq(lockup.isCancelable(vars.expectedStreamId), defaults.CANCELABLE(), "is cancelable");
        assertEq(lockup.isDepleted(vars.expectedStreamId), false, "is depleted");
        assertEq(lockup.isStream(vars.expectedStreamId), true, "is stream");
        assertEq(lockup.isTransferable(vars.expectedStreamId), defaults.TRANSFERABLE(), "is transferable");
        assertEq(lockup.wasCanceled(vars.expectedStreamId), false, "was canceled");

        assertTrue(vars.merkleLL.hasClaimed(vars.indexes[params.posBeforeSort]));

        /*//////////////////////////////////////////////////////////////////////////
                                        CLAWBACK
        //////////////////////////////////////////////////////////////////////////*/

        // Make the campaign owner as the caller.
        resetPrank({ msgSender: params.campaignOwner });

        if (params.expiration > 0) {
            vars.clawbackAmount = uint128(FORK_TOKEN.balanceOf(address(vars.merkleLL)));
            vm.warp({ newTimestamp: uint256(params.expiration) + 1 seconds });

            expectCallToTransfer({ token: FORK_TOKEN, to: params.campaignOwner, value: vars.clawbackAmount });
            vm.expectEmit({ emitter: address(vars.merkleLL) });
            emit ISablierMerkleBase.Clawback({
                to: params.campaignOwner,
                admin: params.campaignOwner,
                amount: vars.clawbackAmount
            });
            vars.merkleLL.clawback({ to: params.campaignOwner, amount: vars.clawbackAmount });
        }

        /*//////////////////////////////////////////////////////////////////////////
                                        COLLECT-FEES
        //////////////////////////////////////////////////////////////////////////*/

        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CollectFees({
            admin: factoryAdmin,
            merkleBase: vars.merkleLL,
            feeAmount: defaults.FEE()
        });
        merkleFactory.collectFees({ merkleBase: vars.merkleLL });

        assertEq(address(vars.merkleLL).balance, 0, "merkleLL ETH balance");
        assertEq(factoryAdmin.balance, initialAdminBalance + defaults.FEE(), "admin ETH balance");
    }
}
