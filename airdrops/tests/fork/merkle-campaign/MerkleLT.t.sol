// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { LockupTranched } from "@sablier/lockup/src/types/DataTypes.sol";
import { Lockup } from "@sablier/lockup/src/types/DataTypes.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { MerkleLT } from "src/types/DataTypes.sol";
import { MerkleBuilder } from "./../../utils/MerkleBuilder.sol";
import { Fork_Test } from "./../Fork.t.sol";

abstract contract MerkleLT_Fork_Test is Fork_Test {
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
        LockupTranched.Tranche[] actualTranches;
        uint128[] amounts;
        MerkleLT.ConstructorParams params;
        uint128 clawbackAmount;
        address expectedLT;
        uint256 expectedStreamId;
        uint256[] indexes;
        uint256 leafPos;
        uint256 leafToClaim;
        ISablierMerkleLT merkleLT;
        bytes32[] merkleProof;
        bytes32 merkleRoot;
        uint256 recipientCount;
        address[] recipients;
    }

    // We need the leaves as a storage variable so that we can use OpenZeppelin's {Arrays.findUpperBound}.
    uint256[] public leaves;

    function testForkFuzz_MerkleLT(Params memory params) external {
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

        vars.expectedLT = computeMerkleLTAddress({
            campaignCreator: params.campaignOwner,
            campaignOwner: params.campaignOwner,
            expiration: params.expiration,
            merkleRoot: vars.merkleRoot,
            token_: FORK_TOKEN
        });

        vars.params = defaults.merkleLTConstructorParams({
            campaignOwner: params.campaignOwner,
            expiration: params.expiration,
            lockup: lockup,
            merkleRoot: vars.merkleRoot,
            token_: FORK_TOKEN
        });

        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(vars.expectedLT),
            params: vars.params,
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount,
            totalDuration: defaults.TOTAL_DURATION(),
            fee: defaults.FEE()
        });

        vars.merkleLT = merkleFactory.createMerkleLT(vars.params, vars.aggregateAmount, vars.recipientCount);

        // Fund the MerkleLT contract.
        deal({ token: address(FORK_TOKEN), to: address(vars.merkleLT), give: vars.aggregateAmount });

        assertGt(address(vars.merkleLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(vars.merkleLT), vars.expectedLT, "MerkleLT contract does not match computed address");

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        // Make the recipient as the caller.
        resetPrank({ msgSender: vars.recipients[params.posBeforeSort] });
        vm.deal(vars.recipients[params.posBeforeSort], 1 ether);

        uint256 initialAdminBalance = factoryAdmin.balance;

        assertFalse(vars.merkleLT.hasClaimed(vars.indexes[params.posBeforeSort]));

        vars.leafToClaim = MerkleBuilder.computeLeaf(
            vars.indexes[params.posBeforeSort],
            vars.recipients[params.posBeforeSort],
            vars.amounts[params.posBeforeSort]
        );
        vars.leafPos = Arrays.findUpperBound(leaves, vars.leafToClaim);

        vars.expectedStreamId = lockup.nextStreamId();
        vm.expectEmit({ emitter: address(vars.merkleLT) });
        emit ISablierMerkleLockup.Claim(
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
            merkleLockup: address(vars.merkleLT),
            fee: defaults.FEE(),
            index: vars.indexes[params.posBeforeSort],
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        vars.merkleLT.claim{ value: defaults.FEE() }({
            index: vars.indexes[params.posBeforeSort],
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        // Assert that the stream has been creatUSDT_MerkleLL_Fork_Tested successfully.
        assertEq(
            lockup.getDepositedAmount(vars.expectedStreamId), vars.amounts[params.posBeforeSort], "deposited amount"
        );
        assertEq(lockup.getEndTime(vars.expectedStreamId), getBlockTimestamp() + defaults.TOTAL_DURATION(), "end time");
        assertEq(lockup.getLockupModel(vars.expectedStreamId), Lockup.Model.LOCKUP_TRANCHED);
        assertEq(lockup.getRecipient(vars.expectedStreamId), vars.recipients[params.posBeforeSort], "recipient");
        assertEq(lockup.getRefundedAmount(vars.expectedStreamId), 0, "refunded amount");
        assertEq(lockup.getSender(vars.expectedStreamId), params.campaignOwner, "sender");
        assertEq(lockup.getStartTime(vars.expectedStreamId), getBlockTimestamp(), "start time");
        assertEq(
            lockup.getTranches(vars.expectedStreamId),
            defaults.tranchesMerkleLT({
                streamStartTime: defaults.STREAM_START_TIME_ZERO(),
                totalAmount: vars.amounts[params.posBeforeSort]
            })
        );
        assertEq(lockup.getUnderlyingToken(vars.expectedStreamId), FORK_TOKEN, "token");
        assertEq(lockup.getWithdrawnAmount(vars.expectedStreamId), 0, "withdrawn amount");
        assertEq(lockup.isCancelable(vars.expectedStreamId), defaults.CANCELABLE(), "is cancelable");
        assertEq(lockup.isDepleted(vars.expectedStreamId), false, "is depleted");
        assertEq(lockup.isStream(vars.expectedStreamId), true, "is stream");
        assertEq(lockup.isTransferable(vars.expectedStreamId), defaults.TRANSFERABLE(), "is transferable");
        assertEq(lockup.wasCanceled(vars.expectedStreamId), false, "was canceled");

        assertTrue(vars.merkleLT.hasClaimed(vars.indexes[params.posBeforeSort]));

        /*//////////////////////////////////////////////////////////////////////////
                                        CLAWBACK
        //////////////////////////////////////////////////////////////////////////*/

        // Make the campaign owner as the caller.
        resetPrank({ msgSender: params.campaignOwner });

        if (params.expiration > 0) {
            vars.clawbackAmount = uint128(FORK_TOKEN.balanceOf(address(vars.merkleLT)));
            vm.warp({ newTimestamp: uint256(params.expiration) + 1 seconds });

            resetPrank({ msgSender: params.campaignOwner });
            expectCallToTransfer({ token: FORK_TOKEN, to: params.campaignOwner, value: vars.clawbackAmount });
            vm.expectEmit({ emitter: address(vars.merkleLT) });
            emit ISablierMerkleBase.Clawback({
                to: params.campaignOwner,
                admin: params.campaignOwner,
                amount: vars.clawbackAmount
            });
            vars.merkleLT.clawback({ to: params.campaignOwner, amount: vars.clawbackAmount });
        }

        /*//////////////////////////////////////////////////////////////////////////
                                        COLLECT-FEES
        //////////////////////////////////////////////////////////////////////////*/

        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CollectFees({
            admin: factoryAdmin,
            merkleBase: vars.merkleLT,
            feeAmount: defaults.FEE()
        });
        merkleFactory.collectFees({ merkleBase: vars.merkleLT });

        assertEq(address(vars.merkleLT).balance, 0, "merkleLT ETH balance");
        assertEq(factoryAdmin.balance, initialAdminBalance + defaults.FEE(), "admin ETH balance");
    }
}
