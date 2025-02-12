// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract CreateMerkleLL_Integration_Test is Integration_Test {
    /// @dev This test works because a default MerkleLL contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();

        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleFactory.createMerkleLL(params, aggregateAmount, recipientCount);
    }

    function test_GivenCustomFeeSet(
        address campaignOwner,
        uint40 expiration,
        uint256 customFee
    )
        external
        givenCampaignNotExists
    {
        // Set the custom fee to 0 for this test.
        resetPrank(users.admin);
        merkleFactory.setCustomFee(users.campaignOwner, customFee);

        resetPrank(users.campaignOwner);
        address expectedLL = computeMerkleLLAddress(campaignOwner, expiration);

        // It should emit a {CreateMerkleLL} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedLL),
            params: merkleLLConstructorParams(campaignOwner, expiration),
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

    function test_GivenCustomFeeNotSet(address campaignOwner, uint40 expiration) external givenCampaignNotExists {
        address expectedLL = computeMerkleLLAddress(campaignOwner, expiration);

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedLL),
            params: merkleLLConstructorParams(campaignOwner, expiration),
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
