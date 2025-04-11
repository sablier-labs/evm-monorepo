// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockupBase } from "src/interfaces/ISablierLockupBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract CollectFees_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Make a withdrawal and pay the fee.
        lockup.withdrawMax{ value: FEE }({ streamId: ids.defaultStream, to: users.recipient });
    }

    function test_RevertWhen_FeeRecipientNotAdmin() external whenCallerNotAdmin {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockupBase_FeeRecipientNotAdmin.selector, users.eve, users.admin)
        );
        lockup.collectFees({ feeRecipient: users.eve });
    }

    function test_WhenFeeRecipientAdmin() external whenCallerNotAdmin {
        // It should transfer fee to the admin.
        _test_CollectFees({ feeRecipient: users.admin });
    }

    function test_WhenFeeRecipientNotContract() external whenCallerAdmin {
        // It should transfer fee to the fee recipient.
        _test_CollectFees({ feeRecipient: users.recipient });
    }

    function test_RevertWhen_FeeRecipientDoesNotImplementReceiveFunction()
        external
        whenCallerAdmin
        whenFeeRecipientContract
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupBase_FeeTransferFail.selector,
                address(contractWithoutReceive),
                address(lockup).balance
            )
        );
        lockup.collectFees({ feeRecipient: address(contractWithoutReceive) });
    }

    function test_WhenFeeRecipientImplementsReceiveFunction() external whenCallerAdmin whenFeeRecipientContract {
        _test_CollectFees(address(contractWithReceive));
    }

    function _test_CollectFees(address feeRecipient) private {
        // Load the initial ETH balance of the fee recipient.
        uint256 initialFeeRecipientBalance = feeRecipient.balance;

        // It should emit a {CollectFees} event.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.CollectFees({ admin: users.admin, feeRecipient: feeRecipient, feeAmount: FEE });

        lockup.collectFees({ feeRecipient: feeRecipient });

        // It should transfer the fee.
        assertEq(feeRecipient.balance, initialFeeRecipientBalance + FEE, "fee recipient ETH balance");

        // It should decrease contract balance to zero.
        assertEq(address(lockup).balance, 0, "lockup ETH balance");
    }
}
