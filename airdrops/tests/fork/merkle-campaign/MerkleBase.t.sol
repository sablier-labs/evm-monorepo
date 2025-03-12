// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";

import { MerkleBuilder } from "./../../utils/MerkleBuilder.sol";
import { Fork_Test } from "./../Fork.t.sol";

abstract contract MerkleBase_Fork_Test is Fork_Test {
    using MerkleBuilder for uint256[];

    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

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
        uint256 initialAdminBalance;
        uint256 aggregateAmount;
        uint128[] amounts;
        uint128 clawbackAmount;
        address expectedMerkleCampaign;
        uint256[] indexes;
        uint128 amountToClaim;
        uint256 indexToClaim;
        address recipientToClaim;
        bytes32[] merkleProof;
        bytes32 merkleRoot;
        uint256 minimumFee;
        uint256 minimumFeeInWei;
        address oracle;
        uint256 recipientCount;
        address[] recipients;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    // We need the leaves as a storage variable so that we can use OpenZeppelin's {Arrays.findUpperBound}.
    uint256[] public leaves;
    Vars internal vars;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 tokenAddress) Fork_Test(tokenAddress) { }

    /*//////////////////////////////////////////////////////////////////////////
                                  CREATE-CAMPAIGN
    //////////////////////////////////////////////////////////////////////////*/

    function preCreateCampaign(Params memory params) internal {
        vm.assume(params.campaignOwner != address(0));
        vm.assume(params.leafData.length > 0);
        assumeNoBlacklisted({ token: address(FORK_TOKEN), addr: params.campaignOwner });
        params.posBeforeSort = _bound(params.posBeforeSort, 0, params.leafData.length - 1);

        // The expiration must be either zero or greater than the block timestamp.
        if (params.expiration != 0) {
            params.expiration = boundUint40(params.expiration, getBlockTimestamp() + 1 seconds, MAX_UNIX_TIMESTAMP);
        }

        // Load the factory admin from mainnet.
        factoryAdmin = merkleFactoryBase.admin();

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

        // Load the mainnet values from the deployed contract.
        vars.oracle = merkleFactoryBase.oracle();
        vars.minimumFee = merkleFactoryBase.minimumFee();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       CLAIM
    //////////////////////////////////////////////////////////////////////////*/

    function preClaim(Params memory params) internal {
        // Fund the Merkle contract.
        deal({ token: address(FORK_TOKEN), to: address(merkleBase), give: vars.aggregateAmount });

        vars.amountToClaim = vars.amounts[params.posBeforeSort];
        vars.indexToClaim = vars.indexes[params.posBeforeSort];
        vars.recipientToClaim = vars.recipients[params.posBeforeSort];

        // Make the recipient as the caller.
        resetPrank({ msgSender: vars.recipientToClaim });
        vm.deal(vars.recipientToClaim, 1 ether);

        assertFalse(merkleBase.hasClaimed(vars.indexToClaim));

        // Compute the Merkle proof.
        if (leaves.length == 1) {
            // If there is only one leaf, the Merkle proof should be an empty array as no proof is needed because the
            // leaf is the root.
        } else {
            vars.merkleProof = getProof({
                data: leaves.toBytes32(),
                node: Arrays.findUpperBound(
                    leaves, MerkleBuilder.computeLeaf(vars.indexToClaim, vars.recipientToClaim, vars.amountToClaim)
                )
            });
        }

        vars.initialAdminBalance = factoryAdmin.balance;
        vars.minimumFeeInWei = merkleBase.minimumFeeInWei();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      CLAWBACK
    //////////////////////////////////////////////////////////////////////////*/

    function testClawback(Params memory params) internal {
        // Make the campaign owner as the caller.
        resetPrank({ msgSender: params.campaignOwner });

        if (params.expiration > 0) {
            vars.clawbackAmount = uint128(FORK_TOKEN.balanceOf(address(merkleBase)));
            vm.warp({ newTimestamp: params.expiration + 1 seconds });

            expectCallToTransfer({ token: FORK_TOKEN, to: params.campaignOwner, value: vars.clawbackAmount });
            vm.expectEmit({ emitter: address(merkleBase) });
            emit ISablierMerkleBase.Clawback({
                to: params.campaignOwner,
                admin: params.campaignOwner,
                amount: vars.clawbackAmount
            });
            merkleBase.clawback({ to: params.campaignOwner, amount: vars.clawbackAmount });
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    COLLECT-FEES
    //////////////////////////////////////////////////////////////////////////*/

    function testCollectFees() internal {
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.CollectFees({
            admin: factoryAdmin,
            merkleBase: merkleBase,
            feeAmount: vars.minimumFeeInWei
        });
        merkleFactoryBase.collectFees({ merkleBase: merkleBase });

        assertEq(address(merkleBase).balance, 0, "merkle ETH balance");
        assertEq(factoryAdmin.balance, vars.initialAdminBalance + vars.minimumFeeInWei, "admin ETH balance");
    }
}
