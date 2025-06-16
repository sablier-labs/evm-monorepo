// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Shared_Integration_Concrete_Test } from "./../Concrete.t.sol";

contract SetNativeToken_Integration_Test is Shared_Integration_Concrete_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        setMsgSender(users.eve);
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.ComptrollerManager_CallerNotComptroller.selector, address(comptroller), users.eve
            )
        );
        flow.setNativeToken(address(dai));
    }

    function test_RevertWhen_ProvidedAddressZero() external whenCallerComptroller {
        address newNativeToken = address(0);

        vm.expectRevert(Errors.SablierFlow_NativeTokenZeroAddress.selector);
        flow.setNativeToken(newNativeToken);
    }

    function test_RevertGiven_NativeTokenAlreadySet() external whenCallerComptroller whenProvidedAddressNotZero {
        // Already set the native token for this test.
        address nativeToken = address(dai);
        flow.setNativeToken(nativeToken);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_NativeTokenAlreadySet.selector, nativeToken));

        // Set native token again with a different address.
        flow.setNativeToken(address(usdc));
    }

    function test_GivenNativeTokenNotSet() external whenCallerComptroller whenProvidedAddressNotZero {
        address nativeToken = address(dai);

        // It should emit a {SetNativeToken} event.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.SetNativeToken({ comptroller: comptroller, nativeToken: nativeToken });

        // Set native token.
        flow.setNativeToken(nativeToken);

        // It should set native token.
        assertEq(flow.nativeToken(), nativeToken, "native token");
    }
}
