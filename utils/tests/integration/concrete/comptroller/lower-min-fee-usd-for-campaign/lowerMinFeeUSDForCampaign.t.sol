// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../../../../Base.t.sol";
import { MerkleMockReverting } from "../../../../mocks/MerkleMock.sol";

contract LowerMinFeeUSDForCampaign_Integration_Concrete_Test is Base_Test {
    uint256 internal newMinFeeUSD = AIRDROP_MIN_FEE_USD - 1;

    function test_RevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.lowerMinFeeUSDForCampaign(address(merkleMock), newMinFeeUSD);
    }

    function test_WhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // It should not revert.
        comptroller.lowerMinFeeUSDForCampaign(address(merkleMock), newMinFeeUSD);
    }

    function test_RevertWhen_CallReverts()
        external
        whenCallerAdmin
        whenCampaignImplementsSablierMerkle
        whenCampaignReturnsTrueForSablierMerkle
    {
        MerkleMockReverting merkleMockReverting = new MerkleMockReverting();

        // It should revert.
        vm.expectRevert("Not gonna happen");
        comptroller.lowerMinFeeUSDForCampaign(address(merkleMockReverting), newMinFeeUSD);
    }

    function test_WhenCallDoesNotRevert()
        external
        whenCallerAdmin
        whenCampaignImplementsSablierMerkle
        whenCampaignReturnsTrueForSablierMerkle
    {
        // It should succeed.
        comptroller.lowerMinFeeUSDForCampaign(address(merkleMock), newMinFeeUSD);
    }
}
