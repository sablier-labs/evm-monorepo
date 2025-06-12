// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";

import { SablierComptroller_Concrete_Test } from "../SablierComptroller.t.sol";

contract CollectFees_Concrete_Test is SablierComptroller_Concrete_Test {
    address internal _feeRecipient;

    function setUp() public override {
        SablierComptroller_Concrete_Test.setUp();

        // Fund the comptroller with some ETH to collect fees.
        deal(address(comptroller), AIRDROP_MIN_FEE_WEI);
    }

    function test_WhenCallerWithFeeCollectorRole() external whenCallerNotAdmin {
        // Change the caller to the accountant which has the fee collector role.
        setMsgSender(users.accountant);

        // It should transfer fee to the fee recipient.
        _test_CollectFees(_feeRecipient);
    }

    function test_RevertWhen_FeeRecipientNotAdmin() external whenCallerNotAdmin whenCallerWithoutFeeCollectorRole {
        setMsgSender(users.alice);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierComptroller_FeeRecipientNotAdmin.selector, users.eve, admin)
        );
        comptroller.collectFees({ feeRecipient: users.eve });
    }

    function test_WhenFeeRecipientAdmin() external whenCallerNotAdmin whenCallerWithoutFeeCollectorRole {
        // It should transfer fee to the admin.
        _test_CollectFees({ feeRecipient: admin });
    }

    function test_WhenFeeRecipientNotContract() external whenCallerAdmin {
        // It should transfer fee to the fee recipient.
        _test_CollectFees(_feeRecipient);
    }

    function test_RevertWhen_FeeRecipientDoesNotImplementReceiveFunction()
        external
        whenCallerAdmin
        whenFeeRecipientContract
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierComptroller_FeeTransferFailed.selector,
                address(contractWithoutReceive),
                address(comptroller).balance
            )
        );
        comptroller.collectFees({ feeRecipient: address(contractWithoutReceive) });
    }

    function test_WhenFeeRecipientImplementsReceiveFunction() external whenCallerAdmin whenFeeRecipientContract {
        _test_CollectFees(address(contractWithReceive));
    }

    function _test_CollectFees(address feeRecipient) private {
        // Load the initial ETH balance of the fee recipient.
        uint256 initialFeeRecipientBalance = feeRecipient.balance;

        // It should emit a {CollectFees} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.CollectFees({ feeRecipient: feeRecipient, feeAmount: AIRDROP_MIN_FEE_WEI });

        comptroller.collectFees({ feeRecipient: feeRecipient });

        // It should decrease contract balance to zero.
        assertEq(address(comptroller).balance, 0, "ETH balance");

        // It should transfer fee to the fee recipient.
        assertEq(feeRecipient.balance, initialFeeRecipientBalance + AIRDROP_MIN_FEE_WEI, "fee recipient ETH balance");
    }
}
