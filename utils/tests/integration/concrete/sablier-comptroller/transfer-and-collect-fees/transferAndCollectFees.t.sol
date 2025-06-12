// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ComptrollerManagerMock } from "src/mocks/ComptrollerManagerMock.sol";

import { SablierComptroller_Concrete_Test } from "../SablierComptroller.t.sol";

contract TransferAndCollectFees_Concrete_Test is SablierComptroller_Concrete_Test {
    SablierFlowAndLockupMock internal flowAndLockup;
    SablierFlowAndLockupMockRevert internal flowAndLockupRevert;

    function setUp() public override {
        SablierComptroller_Concrete_Test.setUp();

        flowAndLockup = new SablierFlowAndLockupMock(address(comptroller));
        flowAndLockupRevert = new SablierFlowAndLockupMockRevert();

        // Fund the comptroller with some ETH to collect fees.
        deal(address(comptroller), AIRDROP_MIN_FEE_WEI);

        // Fund the SablierFlowAndLockupMock with some ETH to transfer fees.
        deal(address(flowAndLockup), LOCKUP_MIN_FEE_WEI + FLOW_MIN_FEE_WEI);
    }

    function test_WhenCallerWithFeeCollectorRole() external whenCallerNotAdmin {
        _test_TransferAndCollectFees(users.accountant);
    }

    function test_RevertWhen_CallerWithoutFeeCollectorRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_COLLECTOR_ROLE));
        comptroller.transferAndCollectFees(address(flowAndLockup), address(flowAndLockup), admin);
    }

    function test_RevertWhen_TheFlowCallReverts() external whenCallerAdmin {
        setMsgSender(admin);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierComptroller_FeeTransferFailed.selector, address(comptroller), 0)
        );
        comptroller.transferAndCollectFees(address(flowAndLockupRevert), address(flowAndLockup), admin);
    }

    function test_RevertWhen_TheLockupCallReverts() external whenCallerAdmin whenTheFlowCallNotRevert {
        setMsgSender(admin);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierComptroller_FeeTransferFailed.selector, address(comptroller), 0)
        );
        comptroller.transferAndCollectFees(address(flowAndLockup), address(flowAndLockupRevert), admin);
    }

    function test_WhenTheLockupCallNotRevert() external whenCallerAdmin whenTheFlowCallNotRevert {
        _test_TransferAndCollectFees(admin);
    }

    function _test_TransferAndCollectFees(address caller) private {
        setMsgSender(caller);

        uint256 previousAdminBalance = admin.balance;
        uint256 totalFeeAmount = AIRDROP_MIN_FEE_WEI + LOCKUP_MIN_FEE_WEI + FLOW_MIN_FEE_WEI;

        // It should emit a {CollectFees} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.CollectFees({ feeRecipient: admin, feeAmount: totalFeeAmount });

        comptroller.transferAndCollectFees(address(flowAndLockup), address(flowAndLockup), admin);

        assertEq(address(flowAndLockup).balance, 0, "Flow and Lockup contract balance should be zero");
        assertEq(address(comptroller).balance, 0, "Comptroller balance should be zero");
        assertEq(admin.balance, previousAdminBalance + totalFeeAmount, "Admin balance should be increased");
    }
}

/// @dev A mock contract to mirror the flow and lockup `transferFeesToComptroller` function.
contract SablierFlowAndLockupMock is ComptrollerManagerMock {
    error SablierLockup_FeeTransferFailed(address comptroller, uint256 feeAmount);

    constructor(address initialComptroller) ComptrollerManagerMock(initialComptroller) { }

    function transferFeesToComptroller() external {
        uint256 feeAmount = address(this).balance;

        // Interaction: transfer the fees to the comptroller.
        (bool success,) = address(comptroller).call{ value: feeAmount }("");

        // Revert if the call failed.
        if (!success) {
            revert SablierLockup_FeeTransferFailed(address(comptroller), feeAmount);
        }
    }
}

contract SablierFlowAndLockupMockRevert {
    function transferFeesToComptroller() external pure {
        revert();
    }
}
