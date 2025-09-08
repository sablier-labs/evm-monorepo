// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { ISablierFactoryMerkleInstant } from "src/interfaces/ISablierFactoryMerkleInstant.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleInstant } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract CreateMerkleInstant_Integration_Test is Integration_Test {
    function test_RevertWhen_NativeTokenFound() external {
        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams();

        // Set dai as the native token.
        setMsgSender(address(comptroller));
        address newNativeToken = address(dai);
        factoryMerkleInstant.setNativeToken(newNativeToken);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleBase_ForbidNativeToken.selector, newNativeToken)
        );
        factoryMerkleInstant.createMerkleInstant(params, AGGREGATE_AMOUNT, AGGREGATE_AMOUNT);
    }

    /// @dev This test reverts because a default MerkleInstant contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external whenNativeTokenNotFound {
        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        createMerkleInstant(params);
    }

    function test_GivenCustomFeeUSDSet() external whenNativeTokenNotFound givenCampaignNotExists {
        // Set a custom fee.
        setMsgSender(admin);
        uint256 customFeeUSD = 0;
        comptroller.setCustomFeeUSDFor(ISablierComptroller.Protocol.Airdrops, users.campaignCreator, customFeeUSD);

        setMsgSender(users.campaignCreator);

        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams();
        params.campaignName = "Merkle Instant campaign with custom fee USD";

        address expectedMerkleInstant = computeMerkleInstantAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(factoryMerkleInstant) });
        emit ISablierFactoryMerkleInstant.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            comptroller: address(comptroller),
            minFeeUSD: customFeeUSD
        });

        ISablierMerkleInstant actualInstant = createMerkleInstant(params);
        assertLt(0, address(actualInstant).code.length, "MerkleInstant contract not created");
        assertEq(
            address(actualInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // It should set the current factory address.
        assertEq(actualInstant.minFeeUSD(), customFeeUSD, "min fee USD");
    }

    function test_GivenCustomFeeUSDNotSet() external whenNativeTokenNotFound givenCampaignNotExists {
        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams();
        params.campaignName = "Merkle Instant campaign with no custom fee USD";

        address expectedMerkleInstant = computeMerkleInstantAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(factoryMerkleInstant) });
        emit ISablierFactoryMerkleInstant.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            comptroller: address(comptroller),
            minFeeUSD: AIRDROP_MIN_FEE_USD
        });

        ISablierMerkleInstant actualInstant = createMerkleInstant(params);
        assertGt(address(actualInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(actualInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // It should set the comptroller address.
        assertEq(address(actualInstant.COMPTROLLER()), address(comptroller), "comptroller address");

        // It should set the min fee.
        assertEq(actualInstant.minFeeUSD(), AIRDROP_MIN_FEE_USD, "min fee USD");
    }
}
