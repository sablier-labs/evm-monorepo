// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract SetNativeToken_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        lockup.setNativeToken(address(dai));
    }

    function test_RevertGiven_NativeTokenAlreadySet() external whenCallerAdmin {
        // Already set the native token for this test.
        address nativeToken = address(dai);
        lockup.setNativeToken(nativeToken);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_NativeTokenAlreadySet.selector, nativeToken));

        // Set native token again with a different address.
        lockup.setNativeToken(address(usdc));
    }

    function test_GivenNativeTokenNotSet() external whenCallerAdmin {
        address nativeToken = address(dai);

        // Set native token.
        lockup.setNativeToken(nativeToken);

        // It should set native token.
        assertEq(lockup.nativeToken(), nativeToken, "native token");
    }
}
