// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Lockup, LockupLinear } from "src/core/types/DataTypes.sol";
import { ISablierMerkleLL } from "src/periphery/interfaces/ISablierMerkleLL.sol";
import { MerkleBase } from "src/periphery/types/DataTypes.sol";

import { MerkleBuilder } from "../../../utils/MerkleBuilder.sol";
import { Fork_Test } from "../Fork.t.sol";

abstract contract MerkleLL_Fork_Test is Fork_Test {
    using MerkleBuilder for uint256[];

    constructor(IERC20 asset_) Fork_Test(asset_) { }

    /// @dev Encapsulates the data needed to compute a Merkle tree leaf.
    struct LeafData {
        uint256 index;
        uint256 recipientSeed;
        uint128 amount;
    }

    struct Params {
        address admin;
        uint40 expiration;
        LeafData[] leafData;
        uint256 posBeforeSort;
    }

    struct Vars {
        LockupLinear.StreamLL actualStream;
        uint256 aggregateAmount;
        uint128[] amounts;
        MerkleBase.ConstructorParams baseParams;
        uint128 clawbackAmount;
        address expectedLL;
        LockupLinear.StreamLL expectedStream;
        uint256 expectedStreamId;
        uint256[] indexes;
        uint256 leafPos;
        uint256 leafToClaim;
        ISablierMerkleLL merkleLL;
        bytes32[] merkleProof;
        bytes32 merkleRoot;
        address[] recipients;
        uint256 recipientCount;
    }

    // We need the leaves as a storage variable so that we can use OpenZeppelin's {Arrays.findUpperBound}.
    uint256[] public leaves;

    function testForkFuzz_MerkleLL(Params memory params) external {
        vm.assume(params.admin != address(0) && params.admin != users.admin);
        vm.assume(params.leafData.length > 0);
        assumeNoBlacklisted({ token: address(FORK_ASSET), addr: params.admin });
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
            vars.recipients[i] = address(uint160(boundedRecipientSeed));
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

        // Make the caller the admin.
        resetPrank({ msgSender: params.admin });

        vars.expectedLL =
            computeMerkleLLAddress(params.admin, params.admin, FORK_ASSET, vars.merkleRoot, params.expiration);

        vars.baseParams = defaults.baseParams({
            admin: params.admin,
            asset_: FORK_ASSET,
            merkleRoot: vars.merkleRoot,
            expiration: params.expiration
        });

        vm.expectEmit({ emitter: address(merkleFactory) });
        emit CreateMerkleLL({
            merkleLL: ISablierMerkleLL(vars.expectedLL),
            baseParams: vars.baseParams,
            lockupLinear: lockupLinear,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamDurations: defaults.durations(),
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount
        });

        vars.merkleLL = merkleFactory.createMerkleLL({
            baseParams: vars.baseParams,
            lockupLinear: lockupLinear,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamDurations: defaults.durations(),
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount
        });

        // Fund the MerkleLL contract.
        deal({ token: address(FORK_ASSET), to: address(vars.merkleLL), give: vars.aggregateAmount });

        assertGt(address(vars.merkleLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(vars.merkleLL), vars.expectedLL, "MerkleLL contract does not match computed address");

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        assertFalse(vars.merkleLL.hasClaimed(vars.indexes[params.posBeforeSort]));

        vars.leafToClaim = MerkleBuilder.computeLeaf(
            vars.indexes[params.posBeforeSort],
            vars.recipients[params.posBeforeSort],
            vars.amounts[params.posBeforeSort]
        );
        vars.leafPos = Arrays.findUpperBound(leaves, vars.leafToClaim);

        vars.expectedStreamId = lockupLinear.nextStreamId();

        vm.expectEmit({ emitter: address(vars.merkleLL) });
        emit Claim(
            vars.indexes[params.posBeforeSort],
            vars.recipients[params.posBeforeSort],
            vars.amounts[params.posBeforeSort],
            vars.expectedStreamId
        );

        // Compute the Merkle proof.
        if (leaves.length == 1) {
            // If there is only one leaf, the Merkle proof should be an empty array as no proof is needed because the
            // leaf is the root.
        }
        else vars.merkleProof = getProof(leaves.toBytes32(), vars.leafPos);

        vars.merkleLL.claim({
            index: vars.indexes[params.posBeforeSort],
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        vars.actualStream = lockupLinear.getStream(vars.expectedStreamId);
        vars.expectedStream = LockupLinear.StreamLL({
            amounts: Lockup.Amounts({ deposited: vars.amounts[params.posBeforeSort], refunded: 0, withdrawn: 0 }),
            asset: FORK_ASSET,
            cliffTime: getBlockTimestamp() + defaults.CLIFF_DURATION(),
            endTime: getBlockTimestamp() + defaults.TOTAL_DURATION(),
            isCancelable: defaults.CANCELABLE(),
            isDepleted: false,
            isStream: true,
            isTransferable: defaults.TRANSFERABLE(),
            recipient: vars.recipients[params.posBeforeSort],
            sender: params.admin,
            startTime: getBlockTimestamp(),
            wasCanceled: false
        });

        assertTrue(vars.merkleLL.hasClaimed(vars.indexes[params.posBeforeSort]));
        assertEq(vars.actualStream, vars.expectedStream);

        /*//////////////////////////////////////////////////////////////////////////
                                        CLAWBACK
        //////////////////////////////////////////////////////////////////////////*/

        if (params.expiration > 0) {
            vars.clawbackAmount = uint128(FORK_ASSET.balanceOf(address(vars.merkleLL)));
            vm.warp({ newTimestamp: uint256(params.expiration) + 1 seconds });

            expectCallToTransfer({ asset: FORK_ASSET, to: params.admin, value: vars.clawbackAmount });
            vm.expectEmit({ emitter: address(vars.merkleLL) });
            emit Clawback({ to: params.admin, admin: params.admin, amount: vars.clawbackAmount });
            vars.merkleLL.clawback({ to: params.admin, amount: vars.clawbackAmount });
        }
    }
}
