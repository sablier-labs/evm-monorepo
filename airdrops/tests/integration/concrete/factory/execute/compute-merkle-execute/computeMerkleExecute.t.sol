// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { MerkleExecute } from "src/types/MerkleExecute.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract ComputeMerkleExecute_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_NativeTokenFound() external {
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();

        // Set dai as the native token.
        setMsgSender(address(comptroller));
        address newNativeToken = address(dai);
        factoryMerkleExecute.setNativeToken(newNativeToken);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleBase_ForbidNativeToken.selector, newNativeToken)
        );
        factoryMerkleExecute.computeMerkleExecute(users.campaignCreator, params);
    }

    function test_RevertWhen_TargetNotContract() external whenNativeTokenNotFound {
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();
        // Set target to an EOA.
        params.target = users.eve;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleExecute_TargetNotContract.selector, users.eve)
        );
        factoryMerkleExecute.computeMerkleExecute(users.campaignCreator, params);
    }

    function test_WhenTargetContract() external view whenNativeTokenNotFound {
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();

        address actualAddress = factoryMerkleExecute.computeMerkleExecute(users.campaignCreator, params);
        address expectedAddress = computeMerkleExecuteAddress();
        assertEq(actualAddress, expectedAddress);
    }
}
