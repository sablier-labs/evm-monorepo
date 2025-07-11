// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ComptrollerableMock } from "src/mocks/ComptrollerableMock.sol";
import { ContractWithoutReceive, ContractWithReceive } from "src/mocks/Receive.sol";

import { Base_Test } from "tests/Base.t.sol";

contract TransferFees_Comptroller_Concrete_Test is Base_Test {
    uint256 internal expectedFeeAmount;
    address[] internal protocolAddresses;

    function setUp() public override {
        Base_Test.setUp();

        // Fund the comptroller with some ETH to collect fees.
        deal(address(comptroller), AIRDROP_MIN_FEE_WEI);

        // Fund the Comptrollerable with some ETH to transfer fees.
        deal(address(comptrollerableMock), LOCKUP_MIN_FEE_WEI);

        expectedFeeAmount = AIRDROP_MIN_FEE_WEI + LOCKUP_MIN_FEE_WEI;

        // Set the protocol addresses.
        protocolAddresses = new address[](1);
        protocolAddresses[0] = address(comptrollerableMock);
    }

    function test_RevertWhen_FeeRecipientZero() external {
        vm.expectRevert(Errors.SablierComptroller_FeeRecipientZero.selector);
        comptroller.transferFees(protocolAddresses, address(0));
    }

    function test_WhenCallerWithFeeCollectorRole() external whenFeeRecipientNotZero whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // Transfer fees to the fee recipient.
        _test_TransferFees(protocolAddresses, users.accountant);
    }

    function test_RevertWhen_FeeRecipientNotAdmin()
        external
        whenFeeRecipientNotZero
        whenCallerNotAdmin
        whenCallerWithoutFeeCollectorRole
    {
        setMsgSender(users.eve);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierComptroller_FeeRecipientNotAdmin.selector, users.accountant, admin)
        );
        comptroller.transferFees(protocolAddresses, users.accountant);
    }

    function test_WhenFeeRecipientAdmin()
        external
        whenFeeRecipientNotZero
        whenCallerNotAdmin
        whenCallerWithoutFeeCollectorRole
    {
        setMsgSender(users.eve);

        // Transfer fees to the admin.
        _test_TransferFees(protocolAddresses, admin);
    }

    function test_RevertWhen_AddressesNotImplementIComptrollerable() external whenFeeRecipientNotZero whenCallerAdmin {
        address[] memory randomAddresses = new address[](1);
        randomAddresses[0] = vm.randomAddress();

        // It should revert.
        vm.expectRevert();
        comptroller.transferFees(randomAddresses, admin);
    }

    function test_WhenAddressesHaveZeroFee()
        external
        whenFeeRecipientNotZero
        whenAddressesImplementIComptrollerable
        whenCallerAdmin
    {
        // Deploy a new comptrollerable contract with no fees.
        comptrollerableMock = new ComptrollerableMock(address(comptroller));
        protocolAddresses[0] = address(comptrollerableMock);

        // Transfer fees to the fee recipient without any incoming fee.
        expectedFeeAmount = AIRDROP_MIN_FEE_WEI;
        _test_TransferFees(protocolAddresses, users.accountant);
    }

    function test_RevertWhen_FeeRecipientWithoutReceive()
        external
        whenAddressesImplementIComptrollerable
        whenCallerAdmin
        whenAddressesHaveFee
        whenFeeRecipientContract
    {
        address feeRecipient = address(new ContractWithoutReceive());

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierComptroller_FeeTransferFailed.selector, feeRecipient, expectedFeeAmount
            )
        );
        comptroller.transferFees(protocolAddresses, feeRecipient);
    }

    function test_WhenFeeRecipientWithReceive()
        external
        whenAddressesImplementIComptrollerable
        whenCallerAdmin
        whenAddressesHaveFee
        whenFeeRecipientContract
    {
        address feeRecipient = address(new ContractWithReceive());

        // Transfer fees to the fee recipient.
        _test_TransferFees(protocolAddresses, feeRecipient);
    }

    function test_WhenFeeRecipientNotContract()
        external
        whenAddressesImplementIComptrollerable
        whenCallerAdmin
        whenAddressesHaveFee
    {
        // Transfer fees to the fee recipient.
        _test_TransferFees(protocolAddresses, users.accountant);
    }

    /// @dev Shared function to test fee transfer.
    function _test_TransferFees(address[] memory targetAddresses, address feeRecipient) private {
        uint256 previousBalance = feeRecipient.balance;

        // It should emit a {TransferFees} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.TransferFees({ feeRecipient: feeRecipient, feeAmount: expectedFeeAmount });

        // Transfer fees to the fee recipient.
        comptroller.transferFees(targetAddresses, feeRecipient);

        // It should transfer fees from comptrollerable contract.
        assertEq(address(comptrollerableMock).balance, 0, "Comptrollerable contract balance");

        // It should decrease comptroller balance to zero.
        assertEq(address(comptroller).balance, 0, "Comptroller balance");

        // It should transfer fees to the fee recipient.
        assertEq(feeRecipient.balance, previousBalance + expectedFeeAmount, "fee recipient balance");
    }
}
