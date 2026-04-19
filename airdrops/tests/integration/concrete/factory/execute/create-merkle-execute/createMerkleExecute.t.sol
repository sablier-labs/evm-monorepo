// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { ISablierFactoryMerkleExecute } from "src/interfaces/ISablierFactoryMerkleExecute.sol";
import { ISablierMerkleExecute } from "src/interfaces/ISablierMerkleExecute.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleExecute } from "src/types/MerkleExecute.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract CreateMerkleExecute_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_NativeTokenFound() external {
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();

        // Set dai as the native token.
        setMsgSender(address(comptroller));
        address newNativeToken = address(dai);
        factoryMerkleExecute.setNativeToken(newNativeToken);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleBase_ForbidNativeToken.selector, newNativeToken)
        );
        factoryMerkleExecute.createMerkleExecute(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
    }

    function test_RevertWhen_TargetNotContract() external whenNativeTokenNotFound {
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();
        // Set target to an EOA.
        params.target = users.eve;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleExecute_TargetNotContract.selector, users.eve)
        );
        factoryMerkleExecute.createMerkleExecute(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
    }

    /// @dev This test reverts because a default MerkleExecute contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external whenNativeTokenNotFound whenTargetContract {
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        createMerkleExecute(params);
    }

    function test_GivenCustomFeeUSDSet() external whenNativeTokenNotFound whenTargetContract givenCampaignNotExists {
        // Set a custom fee.
        setMsgSender(admin);
        uint256 customFeeUSD = 0;
        comptroller.setCustomFeeUSDFor(ISablierComptroller.Protocol.Airdrops, users.campaignCreator, customFeeUSD);

        setMsgSender(users.campaignCreator);

        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();
        params.campaignName = "Merkle Execute campaign with custom fee USD";

        address expectedMerkleExecute = computeMerkleExecuteAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleExecute} event.
        vm.expectEmit({ emitter: address(factoryMerkleExecute) });
        emit ISablierFactoryMerkleExecute.CreateMerkleExecute({
            merkleExecute: ISablierMerkleExecute(expectedMerkleExecute),
            campaignParams: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            comptroller: address(comptroller),
            minFeeUSD: customFeeUSD
        });

        ISablierMerkleExecute actualExecute = createMerkleExecute(params);
        assertLt(0, address(actualExecute).code.length, "MerkleExecute contract not created");
        assertEq(
            address(actualExecute), expectedMerkleExecute, "MerkleExecute contract does not match computed address"
        );

        // It should set the min fee.
        assertEq(actualExecute.minFeeUSD(), customFeeUSD, "min fee USD");
    }

    function test_GivenCustomFeeUSDNotSet() external whenNativeTokenNotFound whenTargetContract givenCampaignNotExists {
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();
        params.campaignName = "Merkle Execute campaign with no custom fee USD";

        address expectedMerkleExecute = computeMerkleExecuteAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleExecute} event.
        vm.expectEmit({ emitter: address(factoryMerkleExecute) });
        emit ISablierFactoryMerkleExecute.CreateMerkleExecute({
            merkleExecute: ISablierMerkleExecute(expectedMerkleExecute),
            campaignParams: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            comptroller: address(comptroller),
            minFeeUSD: AIRDROP_MIN_FEE_USD
        });

        ISablierMerkleExecute actualExecute = createMerkleExecute(params);
        assertGt(address(actualExecute).code.length, 0, "MerkleExecute contract not created");
        assertEq(
            address(actualExecute), expectedMerkleExecute, "MerkleExecute contract does not match computed address"
        );

        // It should set the comptroller address.
        assertEq(address(actualExecute.COMPTROLLER()), address(comptroller), "comptroller address");

        // It should set the min fee.
        assertEq(actualExecute.minFeeUSD(), AIRDROP_MIN_FEE_USD, "min fee USD");

        // It should set the target address.
        assertEq(actualExecute.TARGET(), address(mockStaking), "target address");

        // It should set the selector.
        assertEq(actualExecute.SELECTOR(), mockStaking.stake.selector, "selector");
    }
}
