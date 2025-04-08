// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierFactoryMerkleLL } from "src/interfaces/ISablierFactoryMerkleLL.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract CreateMerkleLL_Integration_Test is Integration_Test {
    function test_RevertWhen_NativeTokenFound() external {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();

        // Set dai as the native token.
        setMsgSender(users.admin);
        address newNativeToken = address(dai);
        factoryMerkleLL.setNativeToken(newNativeToken);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleBase_ForbidNativeToken.selector, newNativeToken)
        );
        factoryMerkleLL.createMerkleLL(params, AGGREGATE_AMOUNT, AGGREGATE_AMOUNT);
    }

    /// @dev This test reverts because a default MerkleLL contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external whenNativeTokenNotFound {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        createMerkleLL(params);
    }

    function test_GivenCustomFeeUSDSet() external whenNativeTokenNotFound givenCampaignNotExists {
        // Set the custom fee for this test.
        setMsgSender(users.admin);
        uint256 customFeeUSD = 0;
        factoryMerkleLL.setCustomFeeUSD(users.campaignCreator, customFeeUSD);

        setMsgSender(users.campaignCreator);
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.campaignName = "Merkle LL campaign with custom fee USD";

        address expectedLL = computeMerkleLLAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleLL} event.
        vm.expectEmit({ emitter: address(factoryMerkleLL) });
        emit ISablierFactoryMerkleLL.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedLL),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            minFeeUSD: customFeeUSD,
            oracle: address(oracle)
        });

        ISablierMerkleLL actualLL = createMerkleLL(params);
        assertLt(0, address(actualLL).code.length, "MerkleLL contract not created");
        assertEq(address(actualLL), expectedLL, "MerkleLL contract does not match computed address");

        // It should set the current factory address.
        assertEq(address(actualLL.FACTORY()), address(factoryMerkleLL), "factory");
        assertEq(actualLL.minFeeUSD(), customFeeUSD, "min fee USD");
    }

    function test_GivenCustomFeeUSDNotSet() external whenNativeTokenNotFound givenCampaignNotExists {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.campaignName = "Merkle LL campaign with no custom fee USD";

        address expectedLL = computeMerkleLLAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(factoryMerkleLL) });
        emit ISablierFactoryMerkleLL.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedLL),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            minFeeUSD: MIN_FEE_USD,
            oracle: address(oracle)
        });

        ISablierMerkleLL actualLL = createMerkleLL(params);
        assertLt(0, address(actualLL).code.length, "MerkleLL contract not created");
        assertEq(address(actualLL), expectedLL, "MerkleLL contract does not match computed address");

        // It should set the correct stream shape.
        assertEq(actualLL.streamShape(), STREAM_SHAPE, "stream shape");

        // It should set the current factory address.
        assertEq(address(actualLL.FACTORY()), address(factoryMerkleLL), "factory");
        assertEq(actualLL.minFeeUSD(), MIN_FEE_USD, "min fee USD");
    }
}
