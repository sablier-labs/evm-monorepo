// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierLockupBase } from "src/interfaces/ISablierLockupBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract SetNativeToken_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        lockup.setNativeToken(address(dai));
    }

    function test_RevertWhen_ProvidedAddressZero() external whenCallerAdmin {
        address newNativeToken = address(0);

        vm.expectRevert(Errors.SablierLockupBase_NativeTokenZeroAddress.selector);
        lockup.setNativeToken(newNativeToken);
    }

    function test_RevertGiven_NativeTokenAlreadySet() external whenCallerAdmin whenProvidedAddressNotZero {
        // Already set the native token for this test.
        address nativeToken = address(dai);
        lockup.setNativeToken(nativeToken);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_NativeTokenAlreadySet.selector, nativeToken));

        // Set native token again with a different address.
        lockup.setNativeToken(address(usdc));
    }

    function test_GivenNativeTokenNotSet() external whenCallerAdmin whenProvidedAddressNotZero {
        address nativeToken = address(dai);

        // It should emit a {SetNativeToken} event.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.SetNativeToken({ admin: users.admin, nativeToken: nativeToken });

        // Set native token.
        lockup.setNativeToken(nativeToken);

        // It should set native token.
        assertEq(lockup.nativeToken(), nativeToken, "native token");
    }
}
