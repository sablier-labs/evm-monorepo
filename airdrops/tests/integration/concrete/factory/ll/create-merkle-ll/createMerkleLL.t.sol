// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryLL } from "src/interfaces/ISablierMerkleFactoryLL.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract CreateMerkleLL_Integration_Test is Integration_Test {
    /// @dev This test reverts because a default MerkleLL contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        createMerkleLL(params);
    }

    function test_GivenCustomFeeSet() external givenCampaignNotExists {
        uint256 customFee = 0;

        // Set the custom fee for this test.
        resetPrank(users.admin);
        merkleFactoryLL.setCustomFee(users.campaignCreator, customFee);

        resetPrank(users.campaignCreator);
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.campaignName = "Merkle LL campaign with custom fee set";

        address expectedLL = computeMerkleLLAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleLL} event.
        vm.expectEmit({ emitter: address(merkleFactoryLL) });
        emit ISablierMerkleFactoryLL.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedLL),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: customFee,
            oracle: address(oracle)
        });

        ISablierMerkleLL actualLL = createMerkleLL(params);
        assertGt(address(actualLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(actualLL), expectedLL, "MerkleLL contract does not match computed address");

        // It should set the current factory address.
        assertEq(actualLL.FACTORY(), address(merkleFactoryLL), "factory");
        assertEq(actualLL.minimumFee(), customFee, "minimum fee");
    }

    function test_GivenCustomFeeNotSet() external givenCampaignNotExists {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.campaignName = "Merkle LL campaign with default fee set";

        address expectedLL = computeMerkleLLAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactoryLL) });
        emit ISablierMerkleFactoryLL.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedLL),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: MINIMUM_FEE,
            oracle: address(oracle)
        });

        ISablierMerkleLL actualLL = createMerkleLL(params);
        assertGt(address(actualLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(actualLL), expectedLL, "MerkleLL contract does not match computed address");

        // It should set the correct shape.
        assertEq(actualLL.shape(), SHAPE, "shape");

        // It should set the current factory address.
        assertEq(actualLL.FACTORY(), address(merkleFactoryLL), "factory");
        assertEq(actualLL.minimumFee(), MINIMUM_FEE, "minimum fee");
    }
}
