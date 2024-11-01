// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierMerkleBase } from "src/periphery/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleInstant } from "src/periphery/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/periphery/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/periphery/interfaces/ISablierMerkleLT.sol";

import { Periphery_Test } from "../../Periphery.t.sol";

abstract contract MerkleCampaign_Integration_Test is Periphery_Test {
    /// @dev A test contract meant to be overridden by the implementing contract, which will be either
    /// {SablierMerkleLL}, {SablierMerkleLT} or {SablierMerkleInstant}.
    ISablierMerkleBase internal merkleBase;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Periphery_Test.setUp();

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
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function claim() internal {
        merkleBase.claim{ value: defaults.DEFAULT_SABLIER_FEE() }({
            index: defaults.INDEX1(),
            recipient: users.recipient1,
            amount: defaults.CLAIM_AMOUNT(),
            merkleProof: defaults.index1Proof()
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-INSTANT
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleInstantAddress() internal view returns (address) {
        return computeMerkleInstantAddress(
            users.campaignOwner, defaults.MERKLE_ROOT(), defaults.EXPIRATION(), defaults.DEFAULT_SABLIER_FEE()
        );
    }

    function computeMerkleInstantAddress(address campaignOwner) internal view returns (address) {
        return computeMerkleInstantAddress(
            campaignOwner, defaults.MERKLE_ROOT(), defaults.EXPIRATION(), defaults.DEFAULT_SABLIER_FEE()
        );
    }

    function computeMerkleInstantAddress(address campaignOwner, uint40 expiration) internal view returns (address) {
        return computeMerkleInstantAddress(
            campaignOwner, defaults.MERKLE_ROOT(), expiration, defaults.DEFAULT_SABLIER_FEE()
        );
    }

    function computeMerkleInstantAddress(
        address campaignOwner,
        uint40 expiration,
        uint256 sablierFee
    )
        internal
        view
        returns (address)
    {
        return computeMerkleInstantAddress(campaignOwner, defaults.MERKLE_ROOT(), expiration, sablierFee);
    }

    function computeMerkleInstantAddress(address campaignOwner, bytes32 merkleRoot) internal view returns (address) {
        return computeMerkleInstantAddress(
            campaignOwner, merkleRoot, defaults.EXPIRATION(), defaults.DEFAULT_SABLIER_FEE()
        );
    }

    function computeMerkleInstantAddress(
        address campaignOwner,
        bytes32 merkleRoot,
        uint40 expiration,
        uint256 sablierFee
    )
        internal
        view
        returns (address)
    {
        return computeMerkleInstantAddress({
            caller: users.campaignOwner,
            campaignOwner: campaignOwner,
            asset_: dai,
            merkleRoot: merkleRoot,
            expiration: expiration,
            sablierFee: sablierFee
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
        return merkleFactory.createMerkleInstant({
            baseParams: defaults.baseParams(campaignOwner, dai, expiration, defaults.MERKLE_ROOT()),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleLLAddress() internal view returns (address) {
        return computeMerkleLLAddress(
            users.campaignOwner, defaults.MERKLE_ROOT(), defaults.EXPIRATION(), defaults.DEFAULT_SABLIER_FEE()
        );
    }

    function computeMerkleLLAddress(address campaignOwner) internal view returns (address) {
        return computeMerkleLLAddress(
            campaignOwner, defaults.MERKLE_ROOT(), defaults.EXPIRATION(), defaults.DEFAULT_SABLIER_FEE()
        );
    }

    function computeMerkleLLAddress(address campaignOwner, uint40 expiration) internal view returns (address) {
        return computeMerkleLLAddress(campaignOwner, defaults.MERKLE_ROOT(), expiration, defaults.DEFAULT_SABLIER_FEE());
    }

    function computeMerkleLLAddress(
        address campaignOwner,
        uint40 expiration,
        uint256 sablierFee
    )
        internal
        view
        returns (address)
    {
        return computeMerkleLLAddress(campaignOwner, defaults.MERKLE_ROOT(), expiration, sablierFee);
    }

    function computeMerkleLLAddress(address campaignOwner, bytes32 merkleRoot) internal view returns (address) {
        return computeMerkleLLAddress(campaignOwner, merkleRoot, defaults.EXPIRATION(), defaults.DEFAULT_SABLIER_FEE());
    }

    function computeMerkleLLAddress(
        address campaignOwner,
        bytes32 merkleRoot,
        uint40 expiration,
        uint256 sablierFee
    )
        internal
        view
        returns (address)
    {
        return computeMerkleLLAddress({
            caller: users.campaignOwner,
            campaignOwner: campaignOwner,
            asset_: dai,
            merkleRoot: merkleRoot,
            expiration: expiration,
            sablierFee: sablierFee
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
        return merkleFactory.createMerkleLL({
            baseParams: defaults.baseParams(campaignOwner, dai, expiration, defaults.MERKLE_ROOT()),
            lockupLinear: lockupLinear,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleLTAddress() internal view returns (address) {
        return computeMerkleLTAddress(
            users.campaignOwner, defaults.MERKLE_ROOT(), defaults.EXPIRATION(), defaults.DEFAULT_SABLIER_FEE()
        );
    }

    function computeMerkleLTAddress(address campaignOwner) internal view returns (address) {
        return computeMerkleLTAddress(
            campaignOwner, defaults.MERKLE_ROOT(), defaults.EXPIRATION(), defaults.DEFAULT_SABLIER_FEE()
        );
    }

    function computeMerkleLTAddress(address campaignOwner, uint40 expiration) internal view returns (address) {
        return computeMerkleLTAddress(campaignOwner, defaults.MERKLE_ROOT(), expiration, defaults.DEFAULT_SABLIER_FEE());
    }

    function computeMerkleLTAddress(
        address campaignOwner,
        uint40 expiration,
        uint256 sablierFee
    )
        internal
        view
        returns (address)
    {
        return computeMerkleLTAddress(campaignOwner, defaults.MERKLE_ROOT(), expiration, sablierFee);
    }

    function computeMerkleLTAddress(address campaignOwner, bytes32 merkleRoot) internal view returns (address) {
        return computeMerkleLTAddress(campaignOwner, merkleRoot, defaults.EXPIRATION(), defaults.DEFAULT_SABLIER_FEE());
    }

    function computeMerkleLTAddress(
        address campaignOwner,
        bytes32 merkleRoot,
        uint40 expiration,
        uint256 sablierFee
    )
        internal
        view
        returns (address)
    {
        return computeMerkleLTAddress({
            caller: users.campaignOwner,
            campaignOwner: campaignOwner,
            asset_: dai,
            merkleRoot: merkleRoot,
            expiration: expiration,
            sablierFee: sablierFee
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
        return merkleFactory.createMerkleLT({
            baseParams: defaults.baseParams(campaignOwner, dai, expiration, defaults.MERKLE_ROOT()),
            lockupTranched: lockupTranched,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamStartTime: defaults.STREAM_START_TIME_ZERO(),
            tranchesWithPercentages: defaults.tranchesWithPercentages(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });
    }
}
