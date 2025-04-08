// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract CollectFees_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotFactory() external {
        // Set the caller to anything other than the factory.
        setMsgSender(users.admin);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_CallerNotFactory.selector, address(factoryMerkleBase), users.admin
            )
        );
        merkleBase.collectFees(users.admin);
    }

    modifier whenCallerFactory() {
        // Claim to collect some fees.
        claim();

        setMsgSender(address(factoryMerkleBase));
        _;
    }

    function test_WhenFeeRecipientNotContract() external whenCallerFactory {
        _test_CollectFees(users.recipient);
    }

    function test_RevertWhen_FeeRecipientDoesNotImplementReceiveFunction()
        external
        whenCallerFactory
        whenFeeRecipientContract
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_FeeTransferFail.selector,
                address(contractWithoutReceive),
                address(merkleBase).balance
            )
        );
        merkleBase.collectFees(address(contractWithoutReceive));
    }

    function test_WhenFeeRecipientImplementsReceiveFunction() external whenCallerFactory whenFeeRecipientContract {
        _test_CollectFees(address(contractWithReceive));
    }

    function _test_CollectFees(address feeRecipient) private {
        // Load the initial ETH balance of the fee recipient.
        uint256 initialFeeRecipientBalance = feeRecipient.balance;

        merkleBase.collectFees(feeRecipient);

        // It should set the ETH balance to 0.
        assertEq(address(merkleBase).balance, 0, "merkle lockup ETH balance");
        // It should transfer fee collected in ETH to the fee recipient.
        assertEq(feeRecipient.balance, initialFeeRecipientBalance + MIN_FEE_WEI, "fee recipient ETH balance");
    }
}
