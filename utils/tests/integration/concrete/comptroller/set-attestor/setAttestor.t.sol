// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract SetAttestor_Comptroller_Concrete_Test is Base_Test {
    address internal newAttestor = makeAddr("newAttestor");

    function test_RevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.setAttestor(newAttestor);
    }

    function test_WhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        address currentAttestor = comptroller.attestor();

        // It should emit a {SetAttestor} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetAttestor(users.accountant, currentAttestor, newAttestor);

        // Set the new attestor.
        comptroller.setAttestor(newAttestor);

        // It should set the attestor.
        assertEq(comptroller.attestor(), newAttestor, "attestor");
    }

    function test_WhenCallerAdmin() external whenCallerAdmin {
        address currentAttestor = comptroller.attestor();

        // It should emit a {SetAttestor} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetAttestor(admin, currentAttestor, newAttestor);

        // Set the new attestor.
        comptroller.setAttestor(newAttestor);

        // It should set the attestor.
        assertEq(comptroller.attestor(), newAttestor, "attestor");
    }
}
