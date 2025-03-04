// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";

import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { ISablierMerkleFactoryVCA } from "src/interfaces/ISablierMerkleFactoryVCA.sol";
import { ISablierMerkleBase, ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";

import { MerkleVCA } from "src/types/DataTypes.sol";

import { MerkleBuilder } from "./../../utils/MerkleBuilder.sol";
import { Fork_Test } from "./../Fork.t.sol";

abstract contract MerkleVCA_Fork_Test is Fork_Test {
    using MerkleBuilder for uint256[];

    constructor(IERC20 tokenAddress) Fork_Test(tokenAddress) { }

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
        MerkleVCA.Timestamps timestamps;
    }

    struct Vars {
        uint256 aggregateAmount;
        uint128[] amounts;
        MerkleVCA.ConstructorParams params;
        uint128 claimableAmount;
        uint128 clawbackAmount;
        address expectedMerkleVCA;
        uint256[] indexes;
        uint256 leafPos;
        uint256 leafToClaim;
        ISablierMerkleVCA merkleVCA;
        bytes32[] merkleProof;
        bytes32 merkleRoot;
        uint256 minimumFee;
        uint256 minimumFeeInWei;
        address oracle;
        address[] recipients;
        uint256 recipientCount;
    }

    // We need the leaves as a storage variable so that we can use OpenZeppelin's {Arrays.findUpperBound}.
    uint256[] public leaves;

    function testForkFuzz_MerkleVCA(Params memory params) external {
        vm.assume(params.campaignOwner != address(0));
        vm.assume(params.leafData.length > 0);
        vm.assume(params.timestamps.end > 0 && params.timestamps.start > 0);
        assumeNoBlacklisted({ token: address(FORK_TOKEN), addr: params.campaignOwner });
        params.posBeforeSort = _bound(params.posBeforeSort, 0, params.leafData.length - 1);

        // Bound unlock start and end times.
        params.timestamps.start = boundUint40(params.timestamps.start, 1, getBlockTimestamp() - 1);
        params.timestamps.end =
            boundUint40(params.timestamps.end, params.timestamps.start + 1, MAX_UNIX_TIMESTAMP - 2 weeks);

        // The expiration must exceed the unlock end time by at least 1 week.
        if (params.timestamps.end > getBlockTimestamp() - 1 weeks) {
            params.expiration = boundUint40(params.expiration, params.timestamps.end + 1 weeks, MAX_UNIX_TIMESTAMP);
        } else {
            // If unlock end time is in the past, set expiration into the future to allow claiming.
            params.expiration = boundUint40(params.expiration, getBlockTimestamp() + 1, MAX_UNIX_TIMESTAMP);
        }

        /*//////////////////////////////////////////////////////////////////////////
                                          CREATE
        //////////////////////////////////////////////////////////////////////////*/

        Vars memory vars;

        // Load the factory admin from mainnet.
        factoryAdmin = merkleFactoryVCA.admin();

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

        vars.expectedMerkleVCA = computeMerkleVCAAddress({
            campaignCreator: params.campaignOwner,
            campaignOwner: params.campaignOwner,
            expiration: params.expiration,
            merkleRoot: vars.merkleRoot,
            timestamps: params.timestamps,
            tokenAddress: FORK_TOKEN
        });

        vars.params = merkleVCAConstructorParams({
            campaignOwner: params.campaignOwner,
            expiration: params.expiration,
            merkleRoot: vars.merkleRoot,
            timestamps: params.timestamps,
            tokenAddress: FORK_TOKEN
        });

        // Load the mainnet values from the deployed contract.
        vars.oracle = merkleFactoryVCA.oracle();
        vars.minimumFee = merkleFactoryVCA.minimumFee();

        vm.expectEmit({ emitter: address(merkleFactoryVCA) });
        emit ISablierMerkleFactoryVCA.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(vars.expectedMerkleVCA),
            params: vars.params,
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount,
            fee: vars.minimumFee,
            oracle: vars.oracle
        });

        vars.merkleVCA = merkleFactoryVCA.createMerkleVCA(vars.params, vars.aggregateAmount, vars.recipientCount);

        // Fund the MerkleVCA contract.
        deal({ token: address(FORK_TOKEN), to: address(vars.merkleVCA), give: vars.aggregateAmount });

        assertGt(address(vars.merkleVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(vars.merkleVCA), vars.expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        // Make the recipient as the caller.
        resetPrank({ msgSender: vars.recipients[params.posBeforeSort] });
        vm.deal(vars.recipients[params.posBeforeSort], 1 ether);

        uint256 initialAdminBalance = factoryAdmin.balance;

        assertFalse(vars.merkleVCA.hasClaimed(vars.indexes[params.posBeforeSort]));

        vars.leafToClaim = MerkleBuilder.computeLeaf(
            vars.indexes[params.posBeforeSort],
            vars.recipients[params.posBeforeSort],
            vars.amounts[params.posBeforeSort]
        );
        vars.leafPos = Arrays.findUpperBound(leaves, vars.leafToClaim);

        if (getBlockTimestamp() >= params.timestamps.end) {
            vars.claimableAmount = vars.amounts[params.posBeforeSort];
        } else {
            // Calculate the claimable amount based on the elapsed time.
            uint40 elapsedTime = getBlockTimestamp() - params.timestamps.start;
            uint40 totalDuration = params.timestamps.end - params.timestamps.start;
            vars.claimableAmount = uint128((uint256(vars.amounts[params.posBeforeSort]) * elapsedTime) / totalDuration);
        }

        vm.expectEmit({ emitter: address(vars.merkleVCA) });
        emit ISablierMerkleVCA.Claim(
            vars.indexes[params.posBeforeSort],
            vars.recipients[params.posBeforeSort],
            vars.claimableAmount,
            vars.amounts[params.posBeforeSort]
        );

        // Compute the Merkle proof.
        if (leaves.length == 1) {
            // If there is only one leaf, the Merkle proof should be an empty array as no proof is needed because the
            // leaf is the root.
        } else {
            vars.merkleProof = getProof(leaves.toBytes32(), vars.leafPos);
        }

        vars.minimumFeeInWei = vars.merkleVCA.minimumFeeInWei();

        expectCallToClaimWithData({
            merkleLockup: address(vars.merkleVCA),
            feeInWei: vars.minimumFeeInWei,
            index: vars.indexes[params.posBeforeSort],
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        expectCallToTransfer({
            token: FORK_TOKEN,
            to: vars.recipients[params.posBeforeSort],
            value: vars.claimableAmount
        });

        vars.merkleVCA.claim{ value: vars.minimumFeeInWei }({
            index: vars.indexes[params.posBeforeSort],
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        assertTrue(vars.merkleVCA.hasClaimed(vars.indexes[params.posBeforeSort]));

        uint256 expectedForgoneAmount = vars.amounts[params.posBeforeSort] - vars.claimableAmount;
        assertEq(vars.merkleVCA.forgoneAmount(), expectedForgoneAmount, "forgoneAmount");

        /*//////////////////////////////////////////////////////////////////////////
                                        CLAWBACK
        //////////////////////////////////////////////////////////////////////////*/

        // Make the campaign owner as the caller.
        resetPrank({ msgSender: params.campaignOwner });

        vars.clawbackAmount = uint128(FORK_TOKEN.balanceOf(address(vars.merkleVCA)));
        vm.warp({ newTimestamp: params.expiration + 1 seconds });

        expectCallToTransfer({ token: FORK_TOKEN, to: params.campaignOwner, value: vars.clawbackAmount });
        vm.expectEmit({ emitter: address(vars.merkleVCA) });
        emit ISablierMerkleBase.Clawback({
            to: params.campaignOwner,
            admin: params.campaignOwner,
            amount: vars.clawbackAmount
        });
        vars.merkleVCA.clawback({ to: params.campaignOwner, amount: vars.clawbackAmount });

        /*//////////////////////////////////////////////////////////////////////////
                                        COLLECT-FEES
        //////////////////////////////////////////////////////////////////////////*/

        vm.expectEmit({ emitter: address(merkleFactoryVCA) });
        emit ISablierMerkleFactoryBase.CollectFees({
            admin: factoryAdmin,
            merkleBase: vars.merkleVCA,
            feeAmount: vars.minimumFeeInWei
        });
        merkleFactoryVCA.collectFees({ merkleBase: vars.merkleVCA });

        assertEq(address(vars.merkleVCA).balance, 0, "merkleVCA ETH balance");
        assertEq(factoryAdmin.balance, initialAdminBalance + vars.minimumFeeInWei, "admin ETH balance");
    }
}
