// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { MerkleInstant } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract ComputeMerkleInstant_Integration_Test is Integration_Test {
    function test_RevertWhen_NativeTokenFound() external {
        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams();

        // Set dai as the native token.
        setMsgSender(address(comptroller));
        address newNativeToken = address(dai);
        factoryMerkleInstant.setNativeToken(newNativeToken);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleBase_ForbidNativeToken.selector, newNativeToken)
        );
        factoryMerkleInstant.computeMerkleInstant(users.campaignCreator, params);
    }

    function test_WhenNativeTokenNotFound() external view whenNativeTokenNotFound {
        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams();

        address actualAddress = factoryMerkleInstant.computeMerkleInstant(users.campaignCreator, params);
        address expectedAddress = computeMerkleInstantAddress();
        assertEq(actualAddress, expectedAddress);
    }
}
