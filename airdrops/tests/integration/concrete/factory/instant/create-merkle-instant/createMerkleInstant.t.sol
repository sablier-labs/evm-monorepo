// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryInstant } from "src/interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { MerkleInstant } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract CreateMerkleInstant_Integration_Test is Integration_Test {
    /// @dev This test reverts because a default MerkleInstant contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external {
        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleFactoryInstant.createMerkleInstant(params, AGGREGATE_AMOUNT, AGGREGATE_AMOUNT);
    }

    function test_GivenCustomFeeSet(
        address campaignOwner,
        uint40 expiration,
        uint256 customFee
    )
        external
        givenCampaignNotExists
    {
        // Set the custom fee for this test.
        resetPrank(users.admin);
        merkleFactoryInstant.setCustomFee(users.campaignOwner, customFee);

        resetPrank(users.campaignOwner);
        address expectedMerkleInstant = computeMerkleInstantAddress(campaignOwner, expiration);

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactoryInstant) });
        emit ISablierMerkleFactoryInstant.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            params: merkleInstantConstructorParams(campaignOwner, expiration),
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: customFee
        });

        ISablierMerkleInstant actualInstant = createMerkleInstant(campaignOwner, expiration);
        assertGt(address(actualInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(actualInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // It should create the campaign with custom fee.
        assertEq(actualInstant.MINIMUM_FEE(), customFee, "custom fee");

        // It should set the current factory address.
        assertEq(actualInstant.FACTORY(), address(merkleFactoryInstant), "factory");
    }

    function test_GivenCustomFeeNotSet(address campaignOwner, uint40 expiration) external givenCampaignNotExists {
        address expectedMerkleInstant = computeMerkleInstantAddress(campaignOwner, expiration);

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactoryInstant) });
        emit ISablierMerkleFactoryInstant.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            params: merkleInstantConstructorParams(campaignOwner, expiration),
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: MINIMUM_FEE
        });

        ISablierMerkleInstant actualInstant = createMerkleInstant(campaignOwner, expiration);
        assertGt(address(actualInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(actualInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // It should create the campaign with custom fee.
        assertEq(actualInstant.MINIMUM_FEE(), MINIMUM_FEE, "minimum fee");

        // It should set the current factory address.
        assertEq(actualInstant.FACTORY(), address(merkleFactoryInstant), "factory");
    }
}
