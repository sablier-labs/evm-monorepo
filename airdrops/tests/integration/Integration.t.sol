// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

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
        resetPrank(users.campaignCreator);

        // Create the default Merkle contracts.
        merkleInstant = createMerkleInstant();
        merkleLL = createMerkleLL();
        merkleLT = createMerkleLT();
        merkleVCA = createMerkleVCA();

        // Fund the contracts.
        deal({ token: address(dai), to: address(merkleInstant), give: AGGREGATE_AMOUNT });
        deal({ token: address(dai), to: address(merkleLL), give: AGGREGATE_AMOUNT });
        deal({ token: address(dai), to: address(merkleLT), give: AGGREGATE_AMOUNT });
        deal({ token: address(dai), to: address(merkleVCA), give: AGGREGATE_AMOUNT });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   MERKLE-BASE
    //////////////////////////////////////////////////////////////////////////*/

    function claim() internal {
        merkleBase.claim{ value: MIN_FEE_WEI }({
            index: INDEX1,
            recipient: users.recipient1,
            amount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-INSTANT
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleInstant() internal returns (ISablierMerkleInstant) {
        return createMerkleInstant(merkleInstantConstructorParams());
    }

    function createMerkleInstant(MerkleInstant.ConstructorParams memory params)
        internal
        returns (ISablierMerkleInstant)
    {
        return factoryMerkleInstant.createMerkleInstant(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleLL() internal returns (ISablierMerkleLL) {
        return createMerkleLL(merkleLLConstructorParams());
    }

    function createMerkleLL(MerkleLL.ConstructorParams memory params) internal returns (ISablierMerkleLL) {
        return factoryMerkleLL.createMerkleLL(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleLT() internal returns (ISablierMerkleLT) {
        return createMerkleLT(merkleLTConstructorParams());
    }

    function createMerkleLT(MerkleLT.ConstructorParams memory params) internal returns (ISablierMerkleLT) {
        return factoryMerkleLT.createMerkleLT(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-VCA
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleVCA() internal returns (ISablierMerkleVCA) {
        return createMerkleVCA(merkleVCAConstructorParams());
    }

    function createMerkleVCA(MerkleVCA.ConstructorParams memory params) internal returns (ISablierMerkleVCA) {
        return factoryMerkleVCA.createMerkleVCA(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
    }
}
