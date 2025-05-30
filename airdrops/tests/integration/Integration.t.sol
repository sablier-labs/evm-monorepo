// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { MerkleInstant, MerkleLL, MerkleLT, MerkleVCA } from "src/types/DataTypes.sol";

import { Base_Test } from "../Base.t.sol";

contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Type of the campaign, e.g., "instant", "ll", "lt", or "vca".
    string internal campaignType;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Make campaign creator the caller.
        setMsgSender(users.campaignCreator);

        // Create the default Merkle contracts and fund them.
        merkleInstant = createMerkleInstant();
        merkleLL = createMerkleLL();
        merkleLT = createMerkleLT();
        merkleVCA = createMerkleVCA();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   MERKLE-CLAIMS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Claim to `users.recipient1` address using {claim} function.
    function claim() internal {
        claim({
            msgValue: MIN_FEE_WEI,
            index: INDEX1,
            recipient: users.recipient1,
            amount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    function claim(
        uint256 msgValue,
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] memory merkleProof
    )
        internal
    {
        if (Strings.equal(campaignType, "instant")) {
            merkleInstant.claim{ value: msgValue }({
                index: index,
                recipient: recipient,
                amount: amount,
                merkleProof: merkleProof
            });
        } else if (Strings.equal(campaignType, "ll")) {
            merkleLL.claim{ value: msgValue }({
                index: index,
                recipient: recipient,
                amount: amount,
                merkleProof: merkleProof
            });
        } else if (Strings.equal(campaignType, "lt")) {
            merkleLT.claim{ value: msgValue }({
                index: index,
                recipient: recipient,
                amount: amount,
                merkleProof: merkleProof
            });
        } else if (Strings.equal(campaignType, "vca")) {
            merkleVCA.claim{ value: msgValue }({
                index: index,
                recipient: recipient,
                fullAmount: amount,
                merkleProof: merkleProof
            });
        }
    }

    /// @dev Claim to Eve address on behalf of `users.recipient1` using {claimTo} function.
    function claimTo() internal {
        claimTo({ msgValue: MIN_FEE_WEI, index: INDEX1, to: users.eve, amount: CLAIM_AMOUNT, merkleProof: index1Proof() });
    }

    function claimTo(
        uint256 msgValue,
        uint256 index,
        address to,
        uint128 amount,
        bytes32[] memory merkleProof
    )
        internal
    {
        if (Strings.equal(campaignType, "instant")) {
            merkleInstant.claimTo{ value: msgValue }({ index: index, to: to, amount: amount, merkleProof: merkleProof });
        } else if (Strings.equal(campaignType, "ll")) {
            merkleLL.claimTo{ value: msgValue }({ index: index, to: to, amount: amount, merkleProof: merkleProof });
        } else if (Strings.equal(campaignType, "lt")) {
            merkleLT.claimTo{ value: msgValue }({ index: index, to: to, amount: amount, merkleProof: merkleProof });
        } else if (Strings.equal(campaignType, "vca")) {
            merkleVCA.claimTo{ value: msgValue }({ index: index, to: to, fullAmount: amount, merkleProof: merkleProof });
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-INSTANT
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleInstant() internal returns (ISablierMerkleInstant) {
        return createMerkleInstant(merkleInstantConstructorParams());
    }

    function createMerkleInstant(MerkleInstant.ConstructorParams memory params)
        internal
        returns (ISablierMerkleInstant campaignAddress)
    {
        campaignAddress = factoryMerkleInstant.createMerkleInstant(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // Fund the campaign.
        fundCampaignWithDai(address(campaignAddress));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleLL() internal returns (ISablierMerkleLL) {
        return createMerkleLL(merkleLLConstructorParams());
    }

    function createMerkleLL(MerkleLL.ConstructorParams memory params)
        internal
        returns (ISablierMerkleLL campaignAddress)
    {
        campaignAddress = factoryMerkleLL.createMerkleLL(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // Fund the campaign.
        fundCampaignWithDai(address(campaignAddress));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleLT() internal returns (ISablierMerkleLT) {
        return createMerkleLT(merkleLTConstructorParams());
    }

    function createMerkleLT(MerkleLT.ConstructorParams memory params)
        internal
        returns (ISablierMerkleLT campaignAddress)
    {
        campaignAddress = factoryMerkleLT.createMerkleLT(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // Fund the campaign.
        fundCampaignWithDai(address(campaignAddress));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-VCA
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleVCA() internal returns (ISablierMerkleVCA) {
        return createMerkleVCA(merkleVCAConstructorParams());
    }

    function createMerkleVCA(MerkleVCA.ConstructorParams memory params)
        internal
        returns (ISablierMerkleVCA campaignAddress)
    {
        campaignAddress = factoryMerkleVCA.createMerkleVCA(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // Fund the campaign.
        fundCampaignWithDai(address(campaignAddress));
    }
}
