// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";

import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { ISablierMerkleFactoryInstant } from "src/interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleBase, ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";

import { MerkleInstant } from "src/types/DataTypes.sol";

import { MerkleBuilder } from "./../../utils/MerkleBuilder.sol";
import { Fork_Test } from "./../Fork.t.sol";

abstract contract MerkleInstant_Fork_Test is Fork_Test {
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
        MerkleInstant.ConstructorParams params;
        uint128 clawbackAmount;
        address expectedMerkleInstant;
        uint256[] indexes;
        uint256 leafPos;
        uint256 leafToClaim;
        ISablierMerkleInstant merkleInstant;
        bytes32[] merkleProof;
        bytes32 merkleRoot;
        uint256 recipientCount;
        address[] recipients;
    }

    // We need the leaves as a storage variable so that we can use OpenZeppelin's {Arrays.findUpperBound}.
    uint256[] public leaves;

    function testForkFuzz_MerkleInstant(Params memory params) external {
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

        // Load the factory admin from mainnet.
        factoryAdmin = merkleFactoryInstant.admin();

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

        vars.expectedMerkleInstant = computeMerkleInstantAddress({
            campaignCreator: params.campaignOwner,
            campaignOwner: params.campaignOwner,
            expiration: params.expiration,
            merkleRoot: vars.merkleRoot,
            token_: FORK_TOKEN
        });

        vars.params = defaults.merkleInstantConstructorParams({
            campaignOwner: params.campaignOwner,
            expiration: params.expiration,
            merkleRoot: vars.merkleRoot,
            token_: FORK_TOKEN
        });

        vm.expectEmit({ emitter: address(merkleFactoryInstant) });
        emit ISablierMerkleFactoryInstant.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(vars.expectedMerkleInstant),
            params: vars.params,
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount,
            fee: defaults.MINIMUM_FEE()
        });

        vars.merkleInstant =
            merkleFactoryInstant.createMerkleInstant(vars.params, vars.aggregateAmount, vars.recipientCount);

        // Fund the MerkleInstant contract.
        deal({ token: address(FORK_TOKEN), to: address(vars.merkleInstant), give: vars.aggregateAmount });

        assertGt(address(vars.merkleInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(vars.merkleInstant),
            vars.expectedMerkleInstant,
            "MerkleInstant contract does not match computed address"
        );

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        // Make the recipient as the caller.
        resetPrank({ msgSender: vars.recipients[params.posBeforeSort] });
        vm.deal(vars.recipients[params.posBeforeSort], 1 ether);

        uint256 initialAdminBalance = factoryAdmin.balance;

        assertFalse(vars.merkleInstant.hasClaimed(vars.indexes[params.posBeforeSort]));

        vars.leafToClaim = MerkleBuilder.computeLeaf(
            vars.indexes[params.posBeforeSort],
            vars.recipients[params.posBeforeSort],
            vars.amounts[params.posBeforeSort]
        );
        vars.leafPos = Arrays.findUpperBound(leaves, vars.leafToClaim);

        vm.expectEmit({ emitter: address(vars.merkleInstant) });
        emit ISablierMerkleInstant.Claim(
            vars.indexes[params.posBeforeSort],
            vars.recipients[params.posBeforeSort],
            vars.amounts[params.posBeforeSort]
        );

        // Compute the Merkle proof.
        if (leaves.length == 1) {
            // If there is only one leaf, the Merkle proof should be an empty array as no proof is needed because the
            // leaf is the root.
        } else {
            vars.merkleProof = getProof(leaves.toBytes32(), vars.leafPos);
        }

        expectCallToClaimWithData({
            merkleLockup: address(vars.merkleInstant),
            fee: defaults.MINIMUM_FEE(),
            index: vars.indexes[params.posBeforeSort],
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        expectCallToTransfer({
            token: FORK_TOKEN,
            to: vars.recipients[params.posBeforeSort],
            value: vars.amounts[params.posBeforeSort]
        });

        vars.merkleInstant.claim{ value: defaults.MINIMUM_FEE() }({
            index: vars.indexes[params.posBeforeSort],
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        assertTrue(vars.merkleInstant.hasClaimed(vars.indexes[params.posBeforeSort]));

        /*//////////////////////////////////////////////////////////////////////////
                                        CLAWBACK
        //////////////////////////////////////////////////////////////////////////*/

        // Make the campaign owner as the caller.
        resetPrank({ msgSender: params.campaignOwner });

        if (params.expiration > 0) {
            vars.clawbackAmount = uint128(FORK_TOKEN.balanceOf(address(vars.merkleInstant)));
            vm.warp({ newTimestamp: params.expiration + 1 seconds });

            expectCallToTransfer({ token: FORK_TOKEN, to: params.campaignOwner, value: vars.clawbackAmount });
            vm.expectEmit({ emitter: address(vars.merkleInstant) });
            emit ISablierMerkleBase.Clawback({
                to: params.campaignOwner,
                admin: params.campaignOwner,
                amount: vars.clawbackAmount
            });
            vars.merkleInstant.clawback({ to: params.campaignOwner, amount: vars.clawbackAmount });
        }

        /*//////////////////////////////////////////////////////////////////////////
                                        COLLECT-FEES
        //////////////////////////////////////////////////////////////////////////*/

        vm.expectEmit({ emitter: address(merkleFactoryInstant) });
        emit ISablierMerkleFactoryBase.CollectFees({
            admin: factoryAdmin,
            merkleBase: vars.merkleInstant,
            feeAmount: defaults.MINIMUM_FEE()
        });
        merkleFactoryInstant.collectFees({ merkleBase: vars.merkleInstant });

        assertEq(address(vars.merkleInstant).balance, 0, "merkleInstant ETH balance");
        assertEq(factoryAdmin.balance, initialAdminBalance + defaults.MINIMUM_FEE(), "admin ETH balance");
    }
}
