// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract ComputeMerkleLL_Integration_Test is Integration_Test {
    function test_RevertWhen_NativeTokenFound() external {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();

        // Set dai as the native token.
        setMsgSender(address(comptroller));
        address newNativeToken = address(dai);
        factoryMerkleLL.setNativeToken(newNativeToken);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleBase_ForbidNativeToken.selector, newNativeToken)
        );
        factoryMerkleLL.computeMerkleLL(users.campaignCreator, params);
    }

    function test_WhenNativeTokenNotFound() external view whenNativeTokenNotFound {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();

        address actualAddress = factoryMerkleLL.computeMerkleLL(users.campaignCreator, params);
        address expectedAddress = computeMerkleLLAddress();
        assertEq(actualAddress, expectedAddress);
    }
}
