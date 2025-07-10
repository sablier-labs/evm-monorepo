// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { ISablierFactoryMerkleLT } from "src/interfaces/ISablierFactoryMerkleLT.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract CreateMerkleLT_Integration_Test is Integration_Test {
    function test_RevertWhen_NativeTokenFound() external {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();

        // Set dai as the native token.
        setMsgSender(address(comptroller));
        address newNativeToken = address(dai);
        factoryMerkleLT.setNativeToken(newNativeToken);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleBase_ForbidNativeToken.selector, newNativeToken)
        );
        factoryMerkleLT.createMerkleLT(params, AGGREGATE_AMOUNT, AGGREGATE_AMOUNT);
    }

    /// @dev This test reverts because a default MerkleLT contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external whenNativeTokenNotFound {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();
        // Expect a revert due to CREATE2.
        vm.expectRevert();
        createMerkleLT(params);
    }

    function test_GivenCustomFeeUSDSet() external whenNativeTokenNotFound givenCampaignNotExists {
        // Set a custom fee.
        setMsgSender(admin);
        uint256 customFeeUSD = 0;
        comptroller.setCustomFeeUSDFor(ISablierComptroller.Protocol.Airdrops, users.campaignCreator, customFeeUSD);

        setMsgSender(users.campaignCreator);
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();
        params.campaignName = "Merkle LT campaign with custom fee USD";

        address expectedLT = computeMerkleLTAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleLT} event.
        vm.expectEmit({ emitter: address(factoryMerkleLT) });
        emit ISablierFactoryMerkleLT.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedLT),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            totalDuration: VESTING_TOTAL_DURATION,
            comptroller: address(comptroller),
            minFeeUSD: customFeeUSD
        });

        ISablierMerkleLT actualLT = createMerkleLT(params);
        assertGt(address(actualLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(actualLT), expectedLT, "MerkleLT contract does not match computed address");

        // It should set the min fee.
        assertEq(actualLT.minFeeUSD(), customFeeUSD, "min fee USD");
    }

    function test_GivenCustomFeeUSDNotSet() external whenNativeTokenNotFound givenCampaignNotExists {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();
        params.campaignName = "Merkle LT campaign with no custom fee USD";

        address expectedLT = computeMerkleLTAddress(params, users.campaignCreator);

        vm.expectEmit({ emitter: address(factoryMerkleLT) });
        emit ISablierFactoryMerkleLT.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedLT),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            totalDuration: VESTING_TOTAL_DURATION,
            comptroller: address(comptroller),
            minFeeUSD: AIRDROP_MIN_FEE_USD
        });

        ISablierMerkleLT actualLT = createMerkleLT(params);
        assertGt(address(actualLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(actualLT), expectedLT, "MerkleLT contract does not match computed address");

        // It should set the correct stream shape.
        assertEq(actualLT.streamShape(), STREAM_SHAPE, "stream shape");

        // It should set the comptroller address.
        assertEq(address(actualLT.COMPTROLLER()), address(comptroller), "comptroller");

        // It should set the min fee.
        assertEq(actualLT.minFeeUSD(), AIRDROP_MIN_FEE_USD, "min fee USD");
    }
}
