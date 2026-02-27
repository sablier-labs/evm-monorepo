// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../../../../Base.t.sol";
import { MerkleMockReverting } from "../../../../mocks/MerkleMock.sol";

contract SetAttestorForCampaign_Comptroller_Concrete_Test is Base_Test {
    address internal newAttestor = makeAddr("newAttestor");

    function test_RevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.setAttestorForCampaign(address(merkleMock), newAttestor);
    }

    function test_WhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // It should succeed.
        comptroller.setAttestorForCampaign(address(merkleMock), newAttestor);
    }

    function test_RevertWhen_CallReverts() external whenCallerAdmin {
        MerkleMockReverting merkleMockReverting = new MerkleMockReverting();

        // It should revert.
        vm.expectRevert("Not gonna happen");
        comptroller.setAttestorForCampaign(address(merkleMockReverting), newAttestor);
    }

    function test_WhenCallDoesNotRevert() external whenCallerAdmin {
        // It should succeed.
        comptroller.setAttestorForCampaign(address(merkleMock), newAttestor);
    }
}
