// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { Errors } from "src/libraries/Errors.sol";

import { RecipientGood } from "../../../../mocks/Hooks.sol";
import { Integration_Test } from "../../../Integration.t.sol";

contract AllowToHook_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Set the comptroller as the caller for this test.
        setMsgSender(address(comptroller));
    }

    function test_RevertWhen_CallerNotComptroller() external {
        // Make Eve the caller in this test.
        setMsgSender(users.eve);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.eve
            )
        );
        lockup.allowToHook(users.eve);
    }

    function test_RevertWhen_ProvidedAddressNotContract() external whenCallerComptroller {
        address eoa = vm.addr({ privateKey: 1 });
        vm.expectRevert();
        lockup.allowToHook(eoa);
    }

    function test_RevertWhen_ProvidedAddressNotReturnInterfaceId()
        external
        whenCallerComptroller
        whenProvidedAddressContract
    {
        // Incorrect interface ID.
        address recipient = address(recipientInterfaceIDIncorrect);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_AllowToHookUnsupportedInterface.selector, recipient)
        );
        lockup.allowToHook(recipient);

        // Missing interface ID.
        recipient = address(recipientInterfaceIDMissing);
        vm.expectRevert(bytes(""));
        lockup.allowToHook(recipient);
    }

    function test_WhenProvidedAddressReturnsInterfaceId() external whenCallerComptroller whenProvidedAddressContract {
        // Define a recipient that implements the interface correctly.
        RecipientGood recipientWithInterfaceId = new RecipientGood();

        // It should emit a {AllowToHook} event.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.AllowToHook(comptroller, address(recipientWithInterfaceId));

        // Allow the provided address to hook.
        lockup.allowToHook(address(recipientWithInterfaceId));

        // It should put the address on the allowlist.
        bool isAllowedToHook = lockup.isAllowedToHook(address(recipientWithInterfaceId));
        assertTrue(isAllowedToHook, "address not put on the allowlist");
    }
}
