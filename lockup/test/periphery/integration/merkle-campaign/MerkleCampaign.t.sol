// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierMerkleInstant } from "src/periphery/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/periphery/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/periphery/interfaces/ISablierMerkleLT.sol";

import { Periphery_Test } from "../../Periphery.t.sol";

abstract contract MerkleCampaign_Integration_Test is Periphery_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Periphery_Test.setUp();

        // Make Alice the caller.
        resetPrank(users.alice);

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
                                    MERKLE-INSTANT
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleInstantAddress() internal view returns (address) {
        return computeMerkleInstantAddress(users.admin, defaults.MERKLE_ROOT(), defaults.EXPIRATION());
    }

    function computeMerkleInstantAddress(address admin) internal view returns (address) {
        return computeMerkleInstantAddress(admin, defaults.MERKLE_ROOT(), defaults.EXPIRATION());
    }

    function computeMerkleInstantAddress(address admin, uint40 expiration) internal view returns (address) {
        return computeMerkleInstantAddress(admin, defaults.MERKLE_ROOT(), expiration);
    }

    function computeMerkleInstantAddress(address admin, bytes32 merkleRoot) internal view returns (address) {
        return computeMerkleInstantAddress(admin, merkleRoot, defaults.EXPIRATION());
    }

    function computeMerkleInstantAddress(
        address admin,
        bytes32 merkleRoot,
        uint40 expiration
    )
        internal
        view
        returns (address)
    {
        return computeMerkleInstantAddress(users.alice, admin, dai, merkleRoot, expiration);
    }

    function createMerkleInstant() internal returns (ISablierMerkleInstant) {
        return createMerkleInstant(users.admin, defaults.EXPIRATION());
    }

    function createMerkleInstant(address admin) internal returns (ISablierMerkleInstant) {
        return createMerkleInstant(admin, defaults.EXPIRATION());
    }

    function createMerkleInstant(uint40 expiration) internal returns (ISablierMerkleInstant) {
        return createMerkleInstant(users.admin, expiration);
    }

    function createMerkleInstant(address admin, uint40 expiration) internal returns (ISablierMerkleInstant) {
        return merkleFactory.createMerkleInstant({
            baseParams: defaults.baseParams(admin, dai, expiration, defaults.MERKLE_ROOT()),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleLLAddress() internal view returns (address) {
        return computeMerkleLLAddress(users.admin, defaults.MERKLE_ROOT(), defaults.EXPIRATION());
    }

    function computeMerkleLLAddress(address admin) internal view returns (address) {
        return computeMerkleLLAddress(admin, defaults.MERKLE_ROOT(), defaults.EXPIRATION());
    }

    function computeMerkleLLAddress(address admin, uint40 expiration) internal view returns (address) {
        return computeMerkleLLAddress(admin, defaults.MERKLE_ROOT(), expiration);
    }

    function computeMerkleLLAddress(address admin, bytes32 merkleRoot) internal view returns (address) {
        return computeMerkleLLAddress(admin, merkleRoot, defaults.EXPIRATION());
    }

    function computeMerkleLLAddress(
        address admin,
        bytes32 merkleRoot,
        uint40 expiration
    )
        internal
        view
        returns (address)
    {
        return computeMerkleLLAddress(users.alice, admin, dai, merkleRoot, expiration);
    }

    function createMerkleLL() internal returns (ISablierMerkleLL) {
        return createMerkleLL(users.admin, defaults.EXPIRATION());
    }

    function createMerkleLL(address admin) internal returns (ISablierMerkleLL) {
        return createMerkleLL(admin, defaults.EXPIRATION());
    }

    function createMerkleLL(uint40 expiration) internal returns (ISablierMerkleLL) {
        return createMerkleLL(users.admin, expiration);
    }

    function createMerkleLL(address admin, uint40 expiration) internal returns (ISablierMerkleLL) {
        return merkleFactory.createMerkleLL({
            baseParams: defaults.baseParams(admin, dai, expiration, defaults.MERKLE_ROOT()),
            lockupLinear: lockupLinear,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamDurations: defaults.durations(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleLTAddress() internal view returns (address) {
        return computeMerkleLTAddress(users.admin, defaults.MERKLE_ROOT(), defaults.EXPIRATION());
    }

    function computeMerkleLTAddress(address admin) internal view returns (address) {
        return computeMerkleLTAddress(admin, defaults.MERKLE_ROOT(), defaults.EXPIRATION());
    }

    function computeMerkleLTAddress(address admin, uint40 expiration) internal view returns (address) {
        return computeMerkleLTAddress(admin, defaults.MERKLE_ROOT(), expiration);
    }

    function computeMerkleLTAddress(address admin, bytes32 merkleRoot) internal view returns (address) {
        return computeMerkleLTAddress(admin, merkleRoot, defaults.EXPIRATION());
    }

    function computeMerkleLTAddress(
        address admin,
        bytes32 merkleRoot,
        uint40 expiration
    )
        internal
        view
        returns (address)
    {
        return computeMerkleLTAddress(users.alice, admin, dai, merkleRoot, expiration);
    }

    function createMerkleLT() internal returns (ISablierMerkleLT) {
        return createMerkleLT(users.admin, defaults.EXPIRATION());
    }

    function createMerkleLT(address admin) internal returns (ISablierMerkleLT) {
        return createMerkleLT(admin, defaults.EXPIRATION());
    }

    function createMerkleLT(uint40 expiration) internal returns (ISablierMerkleLT) {
        return createMerkleLT(users.admin, expiration);
    }

    function createMerkleLT(address admin, uint40 expiration) internal returns (ISablierMerkleLT) {
        return merkleFactory.createMerkleLT({
            baseParams: defaults.baseParams(admin, dai, expiration, defaults.MERKLE_ROOT()),
            lockupTranched: lockupTranched,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            tranchesWithPercentages: defaults.tranchesWithPercentages(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });
    }
}
