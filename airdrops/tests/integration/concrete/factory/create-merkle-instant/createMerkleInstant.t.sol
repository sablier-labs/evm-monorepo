// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { MerkleBase } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract CreateMerkleInstant_Integration_Test is Integration_Test {
    /// @dev This test works because a default MerkleInstant contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleFactory.createMerkleInstant({
            baseParams: baseParams,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount
        });
    }

    function test_WhenCampaignNameExceeds32Bytes() external givenCampaignNotExists {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        baseParams.campaignName = "this string is longer than 32 bytes";

        ISablierMerkleInstant actualInstant = merkleFactory.createMerkleInstant({
            baseParams: baseParams,
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        // It should create the campaign with shape truncated to 32 bytes.
        string memory actualCampaignName = actualInstant.campaignName();
        string memory expectedCampaignName = "this string is longer than 32 by";
        assertEq(actualCampaignName, expectedCampaignName, "shape");
    }

    function test_GivenCustomFeeSet(
        address campaignOwner,
        uint40 expiration,
        uint256 customFee
    )
        external
        givenCampaignNotExists
        whenCampaignNameNotExceed32Bytes
    {
        // Set the custom fee to 0 for this test.
        resetPrank(users.admin);
        merkleFactory.setCustomFee(users.campaignOwner, customFee);

        resetPrank(users.campaignOwner);
        address expectedMerkleInstant = computeMerkleInstantAddress(campaignOwner, expiration);

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            campaignOwner: campaignOwner,
            token_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            baseParams: baseParams,
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            fee: customFee
        });

        ISablierMerkleInstant actualInstant = createMerkleInstant(campaignOwner, expiration);
        assertGt(address(actualInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(actualInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // It should create the campaign with custom fee.
        assertEq(actualInstant.FEE(), customFee, "fee");

        // It should set the current factory address.
        assertEq(actualInstant.FACTORY(), address(merkleFactory), "factory");
    }

    function test_GivenCustomFeeNotSet(
        address campaignOwner,
        uint40 expiration
    )
        external
        givenCampaignNotExists
        whenCampaignNameNotExceed32Bytes
    {
        address expectedMerkleInstant = computeMerkleInstantAddress(campaignOwner, expiration);

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            campaignOwner: campaignOwner,
            token_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            baseParams: baseParams,
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            fee: defaults.FEE()
        });

        ISablierMerkleInstant actualInstant = createMerkleInstant(campaignOwner, expiration);
        assertGt(address(actualInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(actualInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // It should create the campaign with custom fee.
        assertEq(actualInstant.FEE(), defaults.FEE(), "default fee");

        // It should set the current factory address.
        assertEq(actualInstant.FACTORY(), address(merkleFactory), "factory");
    }
}
