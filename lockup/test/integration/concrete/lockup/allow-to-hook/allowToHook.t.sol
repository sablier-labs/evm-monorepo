// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract AllowToHook_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) {
        defaultStreamId = createDefaultStream();
    }

    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        lockup.allowToHook(users.eve);
    }

    modifier whenCallerAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_ProvidedAddressNoCode() external whenCallerAdmin {
        address eoa = vm.addr({ privateKey: 1 });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_AllowToHookZeroCodeSize.selector, eoa));
        lockup.allowToHook(eoa);
    }

    modifier whenProvidedAddressHasCode() {
        _;
    }

    function test_RevertWhen_ProvidedAddressUnsupportedInterface()
        external
        whenCallerAdmin
        whenProvidedAddressHasCode
    {
        // Incorrect interface ID.
        address recipient = address(recipientInterfaceIDIncorrect);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_AllowToHookUnsupportedInterface.selector, recipient)
        );
        lockup.allowToHook(recipient);

        // Missing interface ID.
        recipient = address(recipientInterfaceIDMissing);
        vm.expectRevert(bytes(""));
        lockup.allowToHook(recipient);
    }

    modifier whenProvidedAddressSupportsInterface() {
        _;
    }

    function test_AllowToHook()
        external
        whenCallerAdmin
        whenProvidedAddressHasCode
        whenProvidedAddressSupportsInterface
    {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit AllowToHook(users.admin, address(recipientGood));

        // Allow the provided address to hook.
        lockup.allowToHook(address(recipientGood));

        // Assert that the provided address has been put on the allowlist.
        bool isAllowedToHook = lockup.isAllowedToHook(address(recipientGood));
        assertTrue(isAllowedToHook, "address not put on the allowlist");
    }
}
