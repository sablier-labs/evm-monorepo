// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";

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
        return computeMerkleInstantAddress(campaignOwner, expiration, defaults.FEE());
    }

    function computeMerkleInstantAddress(
        address campaignOwner,
        uint40 expiration,
        uint256 fee
    )
        internal
        view
        returns (address)
    {
        return computeMerkleInstantAddress({
            caller: users.campaignOwner,
            campaignOwner: campaignOwner,
            token_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration,
            fee: fee
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

    function computeMerkleLLAddress(address campaignOwner, uint40 expiration) internal view returns (address) {
        return computeMerkleLLAddress(campaignOwner, expiration, defaults.FEE());
    }

    function computeMerkleLLAddress(
        address campaignOwner,
        uint40 expiration,
        uint256 fee
    )
        internal
        view
        returns (address)
    {
        return computeMerkleLLAddress({
            caller: users.campaignOwner,
            campaignOwner: campaignOwner,
            token_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration,
            fee: fee
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
            lockup: lockup,
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

    function computeMerkleLTAddress(address campaignOwner, uint40 expiration) internal view returns (address) {
        return computeMerkleLTAddress(campaignOwner, expiration, defaults.FEE());
    }

    function computeMerkleLTAddress(
        address campaignOwner,
        uint40 expiration,
        uint256 fee
    )
        internal
        view
        returns (address)
    {
        return computeMerkleLTAddress({
            caller: users.campaignOwner,
            campaignOwner: campaignOwner,
            token_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration,
            fee: fee
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
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamStartTime: defaults.STREAM_START_TIME_ZERO(),
            tranchesWithPercentages: defaults.tranchesWithPercentages(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });
    }
}
