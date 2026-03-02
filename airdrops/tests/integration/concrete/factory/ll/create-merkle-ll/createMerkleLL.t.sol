// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { ISablierFactoryMerkleLL } from "src/interfaces/ISablierFactoryMerkleLL.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleLL } from "src/types/MerkleLL.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract CreateMerkleLL_Integration_Test is Integration_Test {
    function test_RevertWhen_NativeTokenFound() external {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();

        // Set dai as the native token.
        setMsgSender(address(comptroller));
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

    function test_GivenGranularityZero() external whenNativeTokenNotFound givenCampaignNotExists {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.campaignName = "Merkle LL campaign with zero granularity";
        params.granularity = 0;

        _test_CreateMerkleLL(params, AIRDROP_MIN_FEE_USD);
    }

    function test_GivenCustomFeeUSDSet()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        givenGranularityNotZero
    {
        // Set the custom fee for this test.
        setMsgSender(admin);
        uint256 customFeeUSD = 0;
        comptroller.setCustomFeeUSDFor(ISablierComptroller.Protocol.Airdrops, users.campaignCreator, customFeeUSD);

        setMsgSender(users.campaignCreator);
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.campaignName = "Merkle LL campaign with custom fee USD";

        _test_CreateMerkleLL(params, customFeeUSD);
    }

    function test_GivenCustomFeeUSDNotSet()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        givenGranularityNotZero
    {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.campaignName = "Merkle LL campaign with no custom fee USD";

        _test_CreateMerkleLL(params, AIRDROP_MIN_FEE_USD);
    }

    /// @dev Shared helper function.
    function _test_CreateMerkleLL(MerkleLL.ConstructorParams memory params, uint256 expectedMinFeeUSD) private {
        // Declare the expected params with updated granularity value.
        MerkleLL.ConstructorParams memory expectedParams = params;
        expectedParams.granularity = params.granularity == 0 ? 1 seconds : params.granularity;

        // Compute the expected MerkleLL address.
        address expectedLL = computeMerkleLLAddress(expectedParams, users.campaignCreator);

        // It should emit a {CreateMerkleLL} event.
        vm.expectEmit({ emitter: address(factoryMerkleLL) });
        emit ISablierFactoryMerkleLL.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedLL),
            campaignParams: expectedParams,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            comptroller: address(comptroller),
            minFeeUSD: expectedMinFeeUSD
        });

        ISablierMerkleLL actualLL = createMerkleLL(params);
        assertLt(0, address(actualLL).code.length, "MerkleLL contract not created");
        assertEq(address(actualLL), expectedLL, "MerkleLL contract does not match computed address");

        // It should set the correct granularity.
        assertEq(actualLL.VESTING_GRANULARITY(), expectedParams.granularity, "vesting granularity");

        // It should set the min fee.
        assertEq(actualLL.minFeeUSD(), expectedMinFeeUSD, "min fee USD");
    }
}
