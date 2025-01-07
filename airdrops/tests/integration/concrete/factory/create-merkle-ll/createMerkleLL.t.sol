// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { MerkleBase, MerkleLL } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract CreateMerkleLL_Integration_Test is Integration_Test {
    /// @dev This test works because a default MerkleLL contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        bool cancelable = defaults.CANCELABLE();
        bool transferable = defaults.TRANSFERABLE();
        MerkleLL.Schedule memory schedule = defaults.schedule();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleFactory.createMerkleLL({
            baseParams: baseParams,
            lockup: lockup,
            cancelable: cancelable,
            transferable: transferable,
            schedule: schedule,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount
        });
    }

    function test_WhenCampaignNameExceeds32Bytes() external givenCampaignNotExists {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        baseParams.campaignName = "this string is longer than 32 bytes";

        ISablierMerkleLL actualLL = merkleFactory.createMerkleLL({
            baseParams: baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
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

        ISablierMerkleLL actualLL = merkleFactory.createMerkleLL({
            baseParams: baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        // It should create the campaign with shape truncated to 32 bytes.
        string memory actualShape = actualLL.shape();
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
        address expectedLL = computeMerkleLLAddress(campaignOwner, expiration);

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            campaignOwner: campaignOwner,
            token_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        // It should emit a {CreateMerkleLL} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedLL),
            baseParams: baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            fee: customFee
        });

        ISablierMerkleLL actualLL = createMerkleLL(campaignOwner, expiration);
        assertGt(address(actualLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(actualLL), expectedLL, "MerkleLL contract does not match computed address");

        // It should create the campaign with custom fee.
        assertEq(actualLL.FEE(), customFee, "fee");

        // It should set the current factory address.
        assertEq(actualLL.FACTORY(), address(merkleFactory), "factory");
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
        address expectedLL = computeMerkleLLAddress(campaignOwner, expiration);

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            campaignOwner: campaignOwner,
            token_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedLL),
            baseParams: baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            fee: defaults.FEE()
        });

        ISablierMerkleLL actualLL = createMerkleLL(campaignOwner, expiration);
        assertGt(address(actualLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(actualLL), expectedLL, "MerkleLL contract does not match computed address");

        // It should set the correct shape.
        assertEq(actualLL.shape(), defaults.SHAPE(), "shape");

        // It should create the campaign with custom fee.
        assertEq(actualLL.FEE(), defaults.FEE(), "default fee");

        // It should set the current factory address.
        assertEq(actualLL.FACTORY(), address(merkleFactory), "factory");
    }
}
