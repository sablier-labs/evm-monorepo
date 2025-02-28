// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";

import { Base_Test } from "../Base.t.sol";

contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A test contract meant to be overridden by the implementing Merkle campaign contracts.
    ISablierMerkleBase internal merkleBase;

    /// @dev A test contract meant to be overridden by the implementing Merkle factory contracts.
    ISablierMerkleFactoryBase internal merkleFactoryBase;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Make campaign owner the caller.
        resetPrank(users.campaignOwner);

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
        merkleBase.claim{ value: MINIMUM_FEE_IN_WEI }({
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
        return createMerkleInstant(users.campaignOwner, EXPIRATION);
    }

    function createMerkleInstant(address campaignOwner) internal returns (ISablierMerkleInstant) {
        return createMerkleInstant(campaignOwner, EXPIRATION);
    }

    function createMerkleInstant(uint40 expiration) internal returns (ISablierMerkleInstant) {
        return createMerkleInstant(users.campaignOwner, expiration);
    }

    function createMerkleInstant(address campaignOwner, uint40 expiration) internal returns (ISablierMerkleInstant) {
        return merkleFactoryInstant.createMerkleInstant(
            merkleInstantConstructorParams(campaignOwner, expiration), AGGREGATE_AMOUNT, RECIPIENT_COUNT
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleLL() internal returns (ISablierMerkleLL) {
        return createMerkleLL(users.campaignOwner, EXPIRATION);
    }

    function createMerkleLL(address campaignOwner) internal returns (ISablierMerkleLL) {
        return createMerkleLL(campaignOwner, EXPIRATION);
    }

    function createMerkleLL(uint40 expiration) internal returns (ISablierMerkleLL) {
        return createMerkleLL(users.campaignOwner, expiration);
    }

    function createMerkleLL(address campaignOwner, uint40 expiration) internal returns (ISablierMerkleLL) {
        return merkleFactoryLL.createMerkleLL(
            merkleLLConstructorParams(campaignOwner, expiration), AGGREGATE_AMOUNT, RECIPIENT_COUNT
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleLT() internal returns (ISablierMerkleLT) {
        return createMerkleLT(users.campaignOwner, EXPIRATION);
    }

    function createMerkleLT(address campaignOwner) internal returns (ISablierMerkleLT) {
        return createMerkleLT(campaignOwner, EXPIRATION);
    }

    function createMerkleLT(uint40 expiration) internal returns (ISablierMerkleLT) {
        return createMerkleLT(users.campaignOwner, expiration);
    }

    function createMerkleLT(address campaignOwner, uint40 expiration) internal returns (ISablierMerkleLT) {
        return merkleFactoryLT.createMerkleLT(
            merkleLTConstructorParams(campaignOwner, expiration), AGGREGATE_AMOUNT, RECIPIENT_COUNT
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-VCA
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleVCA() internal returns (ISablierMerkleVCA) {
        return createMerkleVCA(users.campaignOwner, EXPIRATION);
    }

    function createMerkleVCA(address campaignOwner) internal returns (ISablierMerkleVCA) {
        return createMerkleVCA(campaignOwner, EXPIRATION);
    }

    function createMerkleVCA(uint40 expiration) internal returns (ISablierMerkleVCA) {
        return createMerkleVCA(users.campaignOwner, expiration);
    }

    function createMerkleVCA(address campaignOwner, uint40 expiration) internal returns (ISablierMerkleVCA) {
        return merkleFactoryVCA.createMerkleVCA(
            merkleVCAConstructorParams(campaignOwner, expiration), AGGREGATE_AMOUNT, RECIPIENT_COUNT
        );
    }
}
