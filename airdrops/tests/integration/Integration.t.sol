// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleExecute } from "src/interfaces/ISablierMerkleExecute.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { ClaimType } from "src/types/MerkleBase.sol";
import { MerkleExecute } from "src/types/MerkleExecute.sol";
import { MerkleInstant } from "src/types/MerkleInstant.sol";
import { MerkleLL } from "src/types/MerkleLL.sol";
import { MerkleLT } from "src/types/MerkleLT.sol";
import { MerkleVCA } from "src/types/MerkleVCA.sol";

import { Base_Test } from "../Base.t.sol";

abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Type of the campaign, e.g., "execute", "instant", "ll", "lt", or "vca".
    string internal campaignType;

    /// @dev Variable to store a campaign deployed with {ClaimType.ATTEST}.
    ISablierMerkleBase internal merkleBaseAttest;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Make campaign creator the caller.
        setMsgSender(users.campaignCreator);

        // Create the default Merkle contracts and fund them.
        merkleExecute = createMerkleExecute();
        merkleInstant = createMerkleInstant();
        merkleLL = createMerkleLL();
        merkleLT = createMerkleLT();
        merkleVCA = createMerkleVCA();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   MERKLE-CLAIMS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Claim to `users.recipient` address using {claim} function.
    function claim() internal virtual {
        claim({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            recipient: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
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
        virtual
    {
        // If the campaign type is "execute", call {claimAndExecute} function.
        if (Strings.equal(campaignType, "execute")) {
            ISablierMerkleExecute(address(merkleBase)).claimAndExecute{ value: msgValue }(
                index, amount, merkleProof, abi.encode(amount)
            );
        }
        // Otherwise, call the `claim` function using the `ISablierMerkleInstant` interface which is compatible with all
        // other Merkle contracts.
        else {
            ISablierMerkleInstant(address(merkleBase)).claim{ value: msgValue }(index, recipient, amount, merkleProof);
        }
    }

    /// @dev Claim to Eve address on behalf of `users.recipient` using {claimTo} function.
    function claimTo() internal {
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.eve,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });
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
        // If the campaign type is "execute", call {claimAndExecute} function.
        if (Strings.equal(campaignType, "execute")) {
            ISablierMerkleExecute(address(merkleBase)).claimAndExecute{ value: msgValue }(
                index, amount, merkleProof, abi.encode(amount)
            );
        }
        // Otherwise, call the `claimTo` function using the `ISablierMerkleInstant` interface which is compatible with
        // all other Merkle contracts.
        else {
            ISablierMerkleInstant(address(merkleBase)).claimTo{ value: msgValue }(index, to, amount, merkleProof);
        }
    }

    /// @dev Claim using default values for {claimViaAttestation} function.
    function claimViaAttestation() internal {
        claimViaAttestation({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.eve,
            amount: CLAIM_AMOUNT,
            expireAt: EXPIRATION,
            merkleProof: getMerkleProof(),
            attestation: generateAttestation()
        });
    }

    function claimViaAttestation(
        uint256 msgValue,
        uint256 index,
        address to,
        uint128 amount,
        uint40 expireAt,
        bytes32[] memory merkleProof,
        bytes memory attestation
    )
        internal
    {
        address campaignAddr = address(merkleBaseAttest);
        // Call the function using the `ISablierMerkleInstant` interface which is compatible with all other Merkle
        // contracts.
        ISablierMerkleInstant(campaignAddr).claimViaAttestation{ value: msgValue }(
            index, to, amount, expireAt, merkleProof, attestation
        );
    }

    /// @dev Claim using default values for {claimViaSig} function.
    function claimViaSig() internal {
        claimViaSig(users.recipient, CLAIM_AMOUNT);
    }

    /// @dev Claim using recipient and amount parameters for {claimViaSig} function.
    function claimViaSig(address recipient, uint128 amount) internal {
        claimViaSig({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(recipient),
            recipient: recipient,
            to: users.eve,
            amount: amount,
            validFrom: VALID_FROM,
            merkleProof: getMerkleProof(recipient),
            signature: generateSignature(recipient, address(merkleBase))
        });
    }

    function claimViaSig(
        uint256 msgValue,
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        uint40 validFrom,
        bytes32[] memory merkleProof,
        bytes memory signature
    )
        internal
    {
        // Using `ISablierMerkleInstant` interface over `merkleBase` works for all Merkle contracts due to similarity in
        // claimViaSig function signature.
        address campaignAddr = address(merkleBase);
        ISablierMerkleInstant(campaignAddr).claimViaSig{ value: msgValue }(
            index, recipient, to, amount, validFrom, merkleProof, signature
        );
    }

    /// @dev Generate the EIP-712 attestation signature with default parameters.
    function generateAttestation() internal view returns (bytes memory) {
        return generateAttestationSignature({
            signerPrivateKey: attestorPrivateKey,
            merkleContract: address(merkleBaseAttest),
            recipient: users.recipient,
            expireAt: EXPIRATION
        });
    }

    /// @dev Generate the EIP-712 signature to claim with default parameters.
    function generateSignature(address user, address merkleContract) internal view returns (bytes memory) {
        return generateEIP712Signature({
            signerPrivateKey: recipientPrivateKey,
            merkleContract: merkleContract,
            index: getIndexInMerkleTree(user),
            recipient: user,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            validFrom: VALID_FROM
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-EXECUTE
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleExecute() internal returns (ISablierMerkleExecute) {
        return createMerkleExecute(merkleExecuteConstructorParams());
    }

    function createMerkleExecute(MerkleExecute.ConstructorParams memory params)
        internal
        returns (ISablierMerkleExecute campaignAddress)
    {
        campaignAddress = factoryMerkleExecute.createMerkleExecute(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // Fund the campaign.
        fundCampaignWithDai(address(campaignAddress));
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

    function createMerkleInstantAttest() internal returns (ISablierMerkleInstant) {
        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams();
        params.campaignName = "attest instant";
        params.claimType = ClaimType.ATTEST;
        return createMerkleInstant(params);
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

    function createMerkleLLAttest() internal returns (ISablierMerkleLL) {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.campaignName = "attest ll";
        params.claimType = ClaimType.ATTEST;
        return createMerkleLL(params);
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

    function createMerkleLTAttest() internal returns (ISablierMerkleLT) {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();
        params.campaignName = "attest lt";
        params.claimType = ClaimType.ATTEST;
        return createMerkleLT(params);
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
        campaignAddress = factoryMerkleVCA.createMerkleVCA(params, RECIPIENT_COUNT);

        // Fund the campaign.
        fundCampaignWithDai(address(campaignAddress));
    }

    function createMerkleVCAAttest() internal returns (ISablierMerkleVCA) {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.campaignName = "attest vca";
        params.claimType = ClaimType.ATTEST;
        return createMerkleVCA(params);
    }
}
