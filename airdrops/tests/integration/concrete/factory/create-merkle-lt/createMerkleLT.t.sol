// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { MerkleBase, MerkleLT } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract CreateMerkleLT_Integration_Test is Integration_Test {
    /// @dev This test works because a default MerkleLT contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        bool cancelable = defaults.CANCELABLE();
        bool transferable = defaults.TRANSFERABLE();
        uint40 streamStartTime = defaults.STREAM_START_TIME_ZERO();
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleFactory.createMerkleLT(
            baseParams,
            lockup,
            cancelable,
            transferable,
            streamStartTime,
            tranchesWithPercentages,
            aggregateAmount,
            recipientCount
        );
    }

    function test_WhenCampaignNameExceeds32Bytes() external givenCampaignNotExists {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        baseParams.campaignName = "this string is longer than 32 bytes";

        ISablierMerkleLT actualLL = merkleFactory.createMerkleLT({
            baseParams: baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamStartTime: defaults.STREAM_START_TIME_ZERO(),
            tranchesWithPercentages: defaults.tranchesWithPercentages(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        // It should create the campaign with shape truncated to 32 bytes.
        string memory actualCampaignName = actualLL.campaignName();
        string memory expectedCampaignName = "this string is longer than 32 by";
        assertEq(actualCampaignName, expectedCampaignName, "shape");
    }

    function test_WhenShapeExceeds32Bytes() external givenCampaignNotExists whenCampaignNameNotExceed32Bytes {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        baseParams.shape = "this string is longer than 32 bytes";

        ISablierMerkleLT actualLT = merkleFactory.createMerkleLT({
            baseParams: baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamStartTime: defaults.STREAM_START_TIME_ZERO(),
            tranchesWithPercentages: defaults.tranchesWithPercentages(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        // It should create the campaign with shape truncated to 32 bytes.
        string memory actualShape = actualLT.shape();
        string memory expectedShape = "this string is longer than 32 by";
        assertEq(actualShape, expectedShape, "shape");
    }

    function test_GivenCustomFeeSet(
        address campaignOwner,
        uint40 expiration,
        uint256 customFee
    )
        external
        givenCampaignNotExists
        whenCampaignNameNotExceed32Bytes
        whenShapeNotExceed32Bytes
    {
        // Set the custom fee to 0 for this test.
        resetPrank(users.admin);
        merkleFactory.setCustomFee(users.campaignOwner, customFee);

        resetPrank(users.campaignOwner);
        address expectedLT = computeMerkleLTAddress(campaignOwner, expiration);

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            campaignOwner: campaignOwner,
            token_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        // It should emit a {CreateMerkleLT} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedLT),
            baseParams: baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamStartTime: defaults.STREAM_START_TIME_ZERO(),
            tranchesWithPercentages: defaults.tranchesWithPercentages(),
            totalDuration: defaults.TOTAL_DURATION(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            fee: customFee
        });

        ISablierMerkleLT actualLT = createMerkleLT(campaignOwner, expiration);
        assertGt(address(actualLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(actualLT), expectedLT, "MerkleLT contract does not match computed address");

        // It should create the campaign with custom fee.
        assertEq(actualLT.FEE(), customFee, "fee");
        // It should set the current factory address.
        assertEq(actualLT.FACTORY(), address(merkleFactory), "factory");
    }

    function test_GivenCustomFeeNotSet(
        address campaignOwner,
        uint40 expiration
    )
        external
        givenCampaignNotExists
        whenCampaignNameNotExceed32Bytes
        whenShapeNotExceed32Bytes
    {
        address expectedLT = computeMerkleLTAddress(campaignOwner, expiration);

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            campaignOwner: campaignOwner,
            token_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedLT),
            baseParams: baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamStartTime: defaults.STREAM_START_TIME_ZERO(),
            tranchesWithPercentages: defaults.tranchesWithPercentages(),
            totalDuration: defaults.TOTAL_DURATION(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            fee: defaults.FEE()
        });

        ISablierMerkleLT actualLT = createMerkleLT(campaignOwner, expiration);
        assertGt(address(actualLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(actualLT), expectedLT, "MerkleLT contract does not match computed address");

        // It should set the correct shape.
        assertEq(actualLT.shape(), defaults.SHAPE(), "shape");

        // It should create the campaign with custom fee.
        assertEq(actualLT.FEE(), defaults.FEE(), "default fee");
        // It should set the current factory address.
        assertEq(actualLT.FACTORY(), address(merkleFactory), "factory");
    }
}
