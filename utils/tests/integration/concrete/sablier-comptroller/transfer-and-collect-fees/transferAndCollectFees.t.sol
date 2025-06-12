// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";

import { SablierComptroller_Concrete_Test } from "../SablierComptroller.t.sol";

contract TransferAndCollectFees_Concrete_Test is SablierComptroller_Concrete_Test {
    function setUp() public override {
        SablierComptroller_Concrete_Test.setUp();

        // Fund the comptroller with some ETH to collect fees.
        deal(address(comptroller), AIRDROP_MIN_FEE_WEI);

        // Fund the ComptrollerManager with some ETH to transfer fees.
        deal(address(comptrollerManager), LOCKUP_MIN_FEE_WEI + FLOW_MIN_FEE_WEI);
    }

    function test_WhenCallerWithFeeCollectorRole() external whenCallerNotAdmin {
        _test_TransferAndCollectFees(users.accountant);
    }

    function test_RevertWhen_CallerWithoutFeeCollectorRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_COLLECTOR_ROLE));
        comptroller.transferAndCollectFees(address(comptrollerManager), address(comptrollerManager), admin);
    }

    function test_WhenCallerAdmin() external whenCallerAdmin whenFlowCallNotRevert {
        _test_TransferAndCollectFees(admin);
    }

    function _test_TransferAndCollectFees(address caller) private {
        setMsgSender(caller);

        uint256 previousAdminBalance = users.accountant.balance;
        uint256 totalFeeAmount = AIRDROP_MIN_FEE_WEI + LOCKUP_MIN_FEE_WEI + FLOW_MIN_FEE_WEI;

        // It should emit a {CollectFees} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.CollectFees({ feeRecipient: users.accountant, feeAmount: totalFeeAmount });

        comptroller.transferAndCollectFees(address(comptrollerManager), address(comptrollerManager), users.accountant);

        assertEq(address(comptrollerManager).balance, 0, "ComptrollerManager contract balance should be zero");
        assertEq(address(comptroller).balance, 0, "Comptroller balance should be zero");
        assertEq(
            users.accountant.balance, previousAdminBalance + totalFeeAmount, "Accountant balance should be increased"
        );
    }
}
