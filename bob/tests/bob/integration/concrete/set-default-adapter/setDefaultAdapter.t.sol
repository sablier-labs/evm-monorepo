// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ComptrollerWithoutMinimalInterfaceId } from "@sablier/evm-utils/src/mocks/ComptrollerMock.sol";

import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetDefaultAdapter_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.depositor
            )
        );
        bob.setDefaultAdapter(dai, adapter);
    }

    function test_RevertWhen_NewAdapterDoesNotSupportInterface()
        external
        whenCallerComptroller
        whenNewAdapterNotZeroAddress
    {
        // Deploy a mock contract that returns `false` for `supportsInterface`.
        ISablierBobAdapter mockAdapterInvalid = ISablierBobAdapter(address(new ComptrollerWithoutMinimalInterfaceId()));

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_NewAdapterMissesInterface.selector, address(mockAdapterInvalid))
        );
        bob.setDefaultAdapter(dai, mockAdapterInvalid);
    }

    function test_WhenNewAdapterSupportsInterface() external whenCallerComptroller whenNewAdapterNotZeroAddress {
        // Check that no adapter is set.
        assertEq(address(bob.getDefaultAdapterFor(dai)), address(0), "adapter");

        // It should emit a {SetDefaultAdapter} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.SetDefaultAdapter({ token: dai, adapter: adapter });

        bob.setDefaultAdapter(dai, adapter);

        // It should set the adapter for the token.
        assertEq(address(bob.getDefaultAdapterFor(dai)), address(adapter), "adapter");
    }

    function test_WhenNewAdapterZeroAddress() external whenCallerComptroller {
        // Check that the adapter is set.
        bob.setDefaultAdapter(weth, adapter);

        // It should emit a {SetDefaultAdapter} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.SetDefaultAdapter({ token: weth, adapter: ISablierBobAdapter(address(0)) });

        bob.setDefaultAdapter(weth, ISablierBobAdapter(address(0)));

        // It should disable the adapter.
        assertEq(address(bob.getDefaultAdapterFor(weth)), address(0), "adapter");
    }
}
