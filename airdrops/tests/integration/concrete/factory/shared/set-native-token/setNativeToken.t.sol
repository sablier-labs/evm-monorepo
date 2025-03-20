// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract SetNativeToken_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.setNativeToken(address(dai));
    }

    function test_RevertWhen_ProvidedAddressZero() external whenCallerAdmin {
        address newNativeToken = address(0);

        vm.expectRevert(Errors.SablierMerkleFactoryBase_NativeTokenZeroAddress.selector);
        merkleFactoryBase.setNativeToken(newNativeToken);
    }

    function test_RevertGiven_NativeTokenAlreadySet() external whenCallerAdmin whenProvidedAddressNotZero {
        // Already set the native token for this test.
        address nativeToken = address(dai);
        merkleFactoryBase.setNativeToken(nativeToken);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleFactoryBase_NativeTokenAlreadySet.selector, nativeToken)
        );

        // Set native token again with a different address.
        merkleFactoryBase.setNativeToken(address(usdc));
    }

    function test_GivenNativeTokenNotSet() external whenCallerAdmin whenProvidedAddressNotZero {
        address nativeToken = address(dai);

        // It should emit a {SetNativeToken} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetNativeToken({ admin: users.admin, nativeToken: nativeToken });

        // Set native token.
        merkleFactoryBase.setNativeToken(nativeToken);

        // It should set native token.
        assertEq(merkleFactoryBase.nativeToken(), nativeToken, "native token");
    }
}
