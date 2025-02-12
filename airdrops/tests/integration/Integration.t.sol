// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { MerkleInstant, MerkleLL, MerkleLT } from "src/types/DataTypes.sol";

import { Base_Test } from "../Base.t.sol";
import { ContractWithoutReceiveEth, ContractWithReceiveEth } from "../mocks/ReceiveEth.sol";

contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ContractWithoutReceiveEth internal contractWithoutReceiveEth;
    ContractWithReceiveEth internal contractWithReceiveEth;

    /// @dev A test contract meant to be overridden by the implementing contract, which will be either
    /// {SablierMerkleLL}, {SablierMerkleLT} or {SablierMerkleInstant}.
    ISablierMerkleBase internal merkleBase;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        contractWithoutReceiveEth = new ContractWithoutReceiveEth();
        contractWithReceiveEth = new ContractWithReceiveEth();
        vm.label({ account: address(contractWithoutReceiveEth), newLabel: "Contract Without Receive Eth" });
        vm.label({ account: address(contractWithReceiveEth), newLabel: "Contract With Receive Eth" });

        // Make campaign owner the caller.
        resetPrank(users.campaignOwner);

        // Create the default Merkle contracts.
        merkleInstant = createMerkleInstant();
        merkleLL = createMerkleLL();
        merkleLT = createMerkleLT();

        // Fund the contracts.
        deal({ token: address(dai), to: address(merkleInstant), give: defaults.AGGREGATE_AMOUNT() });
        deal({ token: address(dai), to: address(merkleLL), give: defaults.AGGREGATE_AMOUNT() });
        deal({ token: address(dai), to: address(merkleLT), give: defaults.AGGREGATE_AMOUNT() });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   MERKLE-BASE
    //////////////////////////////////////////////////////////////////////////*/

    function claim() internal {
        merkleBase.claim{ value: defaults.FEE() }({
            index: defaults.INDEX1(),
            recipient: users.recipient1,
            amount: defaults.CLAIM_AMOUNT(),
            merkleProof: defaults.index1Proof()
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-INSTANT
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleInstantAddress(address campaignOwner, uint40 expiration) internal view returns (address) {
        return computeMerkleInstantAddress({
            campaignCreator: users.campaignOwner,
            campaignOwner: campaignOwner,
            expiration: expiration,
            merkleRoot: defaults.MERKLE_ROOT(),
            token_: dai
        });
    }

    function createMerkleInstant() internal returns (ISablierMerkleInstant) {
        return createMerkleInstant(users.campaignOwner, defaults.EXPIRATION());
    }

    function createMerkleInstant(address campaignOwner) internal returns (ISablierMerkleInstant) {
        return createMerkleInstant(campaignOwner, defaults.EXPIRATION());
    }

    function createMerkleInstant(uint40 expiration) internal returns (ISablierMerkleInstant) {
        return createMerkleInstant(users.campaignOwner, expiration);
    }

    function createMerkleInstant(address campaignOwner, uint40 expiration) internal returns (ISablierMerkleInstant) {
        return merkleFactory.createMerkleInstant(
            defaults.merkleInstantConstructorParams({
                campaignOwner: campaignOwner,
                expiration: expiration,
                merkleRoot: defaults.MERKLE_ROOT(),
                token_: dai
            }),
            defaults.AGGREGATE_AMOUNT(),
            defaults.RECIPIENT_COUNT()
        );
    }

    function merkleInstantConstructorParams() public view returns (MerkleInstant.ConstructorParams memory) {
        return merkleInstantConstructorParams(users.campaignOwner, defaults.EXPIRATION());
    }

    function merkleInstantConstructorParams(
        address campaignOwner,
        uint40 expiration
    )
        public
        view
        returns (MerkleInstant.ConstructorParams memory)
    {
        return defaults.merkleInstantConstructorParams({
            campaignOwner: campaignOwner,
            expiration: expiration,
            merkleRoot: defaults.MERKLE_ROOT(),
            token_: dai
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleLLAddress(address campaignOwner, uint40 expiration) internal view returns (address) {
        return computeMerkleLLAddress({
            campaignCreator: users.campaignOwner,
            campaignOwner: campaignOwner,
            expiration: expiration,
            merkleRoot: defaults.MERKLE_ROOT(),
            token_: dai
        });
    }

    function createMerkleLL() internal returns (ISablierMerkleLL) {
        return createMerkleLL(users.campaignOwner, defaults.EXPIRATION());
    }

    function createMerkleLL(address campaignOwner) internal returns (ISablierMerkleLL) {
        return createMerkleLL(campaignOwner, defaults.EXPIRATION());
    }

    function createMerkleLL(uint40 expiration) internal returns (ISablierMerkleLL) {
        return createMerkleLL(users.campaignOwner, expiration);
    }

    function createMerkleLL(address campaignOwner, uint40 expiration) internal returns (ISablierMerkleLL) {
        return merkleFactory.createMerkleLL(
            defaults.merkleLLConstructorParams({
                campaignOwner: campaignOwner,
                expiration: expiration,
                lockup: lockup,
                merkleRoot: defaults.MERKLE_ROOT(),
                token_: dai
            }),
            defaults.AGGREGATE_AMOUNT(),
            defaults.RECIPIENT_COUNT()
        );
    }

    function merkleLLConstructorParams() public view returns (MerkleLL.ConstructorParams memory) {
        return merkleLLConstructorParams(users.campaignOwner, defaults.EXPIRATION());
    }

    function merkleLLConstructorParams(
        address campaignOwner,
        uint40 expiration
    )
        public
        view
        returns (MerkleLL.ConstructorParams memory)
    {
        return defaults.merkleLLConstructorParams({
            campaignOwner: campaignOwner,
            expiration: expiration,
            lockup: lockup,
            merkleRoot: defaults.MERKLE_ROOT(),
            token_: dai
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleLTAddress(address campaignOwner, uint40 expiration) internal view returns (address) {
        return computeMerkleLTAddress({
            campaignCreator: users.campaignOwner,
            campaignOwner: campaignOwner,
            expiration: expiration,
            merkleRoot: defaults.MERKLE_ROOT(),
            token_: dai
        });
    }

    function createMerkleLT() internal returns (ISablierMerkleLT) {
        return createMerkleLT(users.campaignOwner, defaults.EXPIRATION());
    }

    function createMerkleLT(address campaignOwner) internal returns (ISablierMerkleLT) {
        return createMerkleLT(campaignOwner, defaults.EXPIRATION());
    }

    function createMerkleLT(uint40 expiration) internal returns (ISablierMerkleLT) {
        return createMerkleLT(users.campaignOwner, expiration);
    }

    function createMerkleLT(address campaignOwner, uint40 expiration) internal returns (ISablierMerkleLT) {
        return merkleFactory.createMerkleLT(
            defaults.merkleLTConstructorParams({
                campaignOwner: campaignOwner,
                expiration: expiration,
                lockup: lockup,
                merkleRoot: defaults.MERKLE_ROOT(),
                token_: dai
            }),
            defaults.AGGREGATE_AMOUNT(),
            defaults.RECIPIENT_COUNT()
        );
    }

    function merkleLTConstructorParams() public view returns (MerkleLT.ConstructorParams memory) {
        return merkleLTConstructorParams(users.campaignOwner, defaults.EXPIRATION());
    }

    function merkleLTConstructorParams(
        address campaignOwner,
        uint40 expiration
    )
        public
        view
        returns (MerkleLT.ConstructorParams memory)
    {
        return defaults.merkleLTConstructorParams({
            campaignOwner: campaignOwner,
            expiration: expiration,
            lockup: lockup,
            merkleRoot: defaults.MERKLE_ROOT(),
            token_: dai
        });
    }
}
