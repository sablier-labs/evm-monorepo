// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract CollectFees_Integration_Test is Integration_Test {
    function test_RevertWhen_ProvidedMerkleLockupNotValid() external {
        vm.expectRevert();
        factoryMerkleBase.collectFees({ campaign: ISablierMerkleBase(users.eve), feeRecipient: users.admin });
    }

    function test_WhenCallerWithFeeCollectorRole() external whenProvidedMerkleLockupValid whenCallerNotAdmin {
        // Change the caller to the accountant which has the fee collector role.
        setMsgSender(users.accountant);

        // It should transfer fee to the fee recipient.
        _test_CollectFees({ feeRecipient: users.recipient });
    }

    function test_RevertWhen_FeeRecipientNotAdmin()
        external
        whenProvidedMerkleLockupValid
        whenCallerNotAdmin
        whenCallerWithoutFeeCollectorRole
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleFactoryBase_FeeRecipientNotAdmin.selector, users.eve, users.admin
            )
        );
        factoryMerkleBase.collectFees({ campaign: merkleBase, feeRecipient: users.eve });
    }

    function test_WhenFeeRecipientAdmin()
        external
        whenProvidedMerkleLockupValid
        whenCallerNotAdmin
        whenCallerWithoutFeeCollectorRole
    {
        // It should transfer fee to the admin.
        _test_CollectFees({ feeRecipient: users.admin });
    }

    function test_WhenFeeRecipientNotContract() external whenProvidedMerkleLockupValid whenCallerAdmin {
        // It should transfer fee to the fee recipient.
        _test_CollectFees({ feeRecipient: users.recipient });
    }

    function test_RevertWhen_FeeRecipientDoesNotImplementReceiveFunction()
        external
        whenProvidedMerkleLockupValid
        whenCallerAdmin
        whenFeeRecipientContract
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_FeeTransferFail.selector,
                address(contractWithoutReceive),
                address(merkleBase).balance
            )
        );
        factoryMerkleBase.collectFees({ campaign: merkleBase, feeRecipient: address(contractWithoutReceive) });
    }

    function test_WhenFeeRecipientImplementsReceiveFunction()
        external
        whenProvidedMerkleLockupValid
        whenCallerAdmin
        whenFeeRecipientContract
    {
        _test_CollectFees(address(contractWithReceive));
    }

    function _test_CollectFees(address feeRecipient) private {
        // Load the initial ETH balance of the fee recipient.
        uint256 initialFeeRecipientBalance = feeRecipient.balance;

        // It should emit a {CollectFees} event.
        vm.expectEmit({ emitter: address(factoryMerkleBase) });
        emit ISablierFactoryMerkleBase.CollectFees({
            admin: users.admin,
            campaign: merkleBase,
            feeRecipient: feeRecipient,
            feeAmount: MIN_FEE_WEI
        });

        factoryMerkleBase.collectFees({ campaign: merkleBase, feeRecipient: feeRecipient });

        // It should decrease merkle contract balance to zero.
        assertEq(address(merkleBase).balance, 0, "merkle lockup ETH balance");

        // It should transfer fee to the fee recipient.
        assertEq(feeRecipient.balance, initialFeeRecipientBalance + MIN_FEE_WEI, "fee recipient ETH balance");
    }
}
