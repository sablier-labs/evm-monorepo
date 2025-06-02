// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract CollectFees_Integration_Test is Integration_Test {
    function test_WhenCallerWithFeeCollectorRole() external whenCallerNotAdmin {
        // Change the caller to the accountant which has the fee collector role.
        setMsgSender(users.accountant);

        // It should transfer fee to the fee recipient.
        _test_CollectFees({ feeRecipient: users.recipient });
    }

    function test_RevertWhen_FeeRecipientNotAdmin() external whenCallerNotAdmin whenCallerWithoutFeeCollectorRole {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFactoryMerkleBase_FeeRecipientNotAdmin.selector, users.eve, users.admin
            )
        );
        factoryMerkleBase.collectFees({ feeRecipient: users.eve });
    }

    function test_WhenFeeRecipientAdmin() external whenCallerNotAdmin whenCallerWithoutFeeCollectorRole {
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
                Errors.SablierFactoryMerkleBase_FeeTransferFailed.selector,
                address(contractWithoutReceive),
                address(factoryMerkleBase).balance
            )
        );
        factoryMerkleBase.collectFees({ feeRecipient: address(contractWithoutReceive) });
    }

    function test_WhenFeeRecipientImplementsReceiveFunction() external whenCallerAdmin whenFeeRecipientContract {
        _test_CollectFees(address(contractWithReceive));
    }

    function _test_CollectFees(address feeRecipient) private {
        // Load the initial ETH balance of the fee recipient.
        uint256 initialFeeRecipientBalance = feeRecipient.balance;

        // It should emit a {CollectFees} event.
        vm.expectEmit({ emitter: address(factoryMerkleBase) });
        emit ISablierFactoryMerkleBase.CollectFees({
            admin: users.admin,
            feeRecipient: feeRecipient,
            feeAmount: MIN_FEE_WEI
        });

        factoryMerkleBase.collectFees({ feeRecipient: feeRecipient });

        // It should decrease contract balance to zero.
        assertEq(address(factoryMerkleBase).balance, 0, "ETH balance");

        // It should transfer fee to the fee recipient.
        assertEq(feeRecipient.balance, initialFeeRecipientBalance + MIN_FEE_WEI, "fee recipient ETH balance");
    }
}
