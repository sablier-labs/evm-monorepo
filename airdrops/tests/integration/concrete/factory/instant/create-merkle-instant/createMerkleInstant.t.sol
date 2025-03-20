// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryInstant } from "src/interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleInstant } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract CreateMerkleInstant_Integration_Test is Integration_Test {
    function test_RevertWhen_NativeTokenFound() external {
        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams();

        // Set dai as the native token.
        resetPrank(users.admin);
        address newNativeToken = address(dai);
        merkleFactoryInstant.setNativeToken(newNativeToken);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleFactoryBase_ForbidNativeToken.selector, newNativeToken)
        );
        merkleFactoryInstant.createMerkleInstant(params, AGGREGATE_AMOUNT, AGGREGATE_AMOUNT);
    }

    /// @dev This test reverts because a default MerkleInstant contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external whenNativeTokenNotFound {
        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        createMerkleInstant(params);
    }

    function test_GivenCustomFeeSet() external whenNativeTokenNotFound givenCampaignNotExists {
        uint256 customFee = 0;

        // Set the custom fee for this test.
        resetPrank(users.admin);
        merkleFactoryInstant.setCustomFee(users.campaignCreator, customFee);

        resetPrank(users.campaignCreator);

        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams();
        params.campaignName = "Merkle Instant campaign with custom fee set";

        address expectedMerkleInstant = computeMerkleInstantAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactoryInstant) });
        emit ISablierMerkleFactoryInstant.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: customFee,
            oracle: address(oracle)
        });

        ISablierMerkleInstant actualInstant = createMerkleInstant(params);
        assertGt(address(actualInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(actualInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // It should set the current factory address.
        assertEq(actualInstant.FACTORY(), address(merkleFactoryInstant));
        assertEq(actualInstant.minimumFee(), customFee, "minimum fee");
    }

    function test_GivenCustomFeeNotSet() external whenNativeTokenNotFound givenCampaignNotExists {
        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams();
        params.campaignName = "Merkle Instant campaign with default fee set";

        address expectedMerkleInstant = computeMerkleInstantAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactoryInstant) });
        emit ISablierMerkleFactoryInstant.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: MINIMUM_FEE,
            oracle: address(oracle)
        });

        ISablierMerkleInstant actualInstant = createMerkleInstant(params);
        assertGt(address(actualInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(actualInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // It should set the current factory address.
        assertEq(actualInstant.FACTORY(), address(merkleFactoryInstant));
        assertEq(actualInstant.minimumFee(), MINIMUM_FEE, "minimum fee");
    }
}
