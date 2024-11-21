// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract WithdrawFees_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotFactory() external {
        // Set the caller to anything other than the factory.
        resetPrank(users.admin);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_CallerNotFactory.selector, address(merkleFactory), users.admin
            )
        );
        merkleBase.withdrawFees(users.admin);
    }

    modifier whenCallerFactory() {
        // Claim to collect some fees.
        claim();

        resetPrank(address(merkleFactory));
        _;
    }

    function test_WhenProvidedAddressNotContract() external whenCallerFactory {
        uint256 previousToBalance = users.admin.balance;

        merkleBase.withdrawFees(users.admin);

        // It should set the ETH balance to 0.
        assertEq(address(merkleBase).balance, 0, "merkle lockup eth balance");
        // It should transfer fee collected in ETH to the provided address.
        assertEq(users.admin.balance, previousToBalance + defaults.DEFAULT_FEE(), "eth balance");
    }

    function test_RevertWhen_ProvidedAddressNotImplementReceiveEth()
        external
        whenCallerFactory
        whenProvidedAddressContract
    {
        address payable noReceiveEth = payable(address(contractWithoutReceiveEth));
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_FeeWithdrawFailed.selector, noReceiveEth, address(merkleBase).balance
            )
        );
        merkleBase.withdrawFees(noReceiveEth);
    }

    function test_WhenProvidedAddressImplementReceiveEth() external whenCallerFactory whenProvidedAddressContract {
        address payable receiveEth = payable(address(contractWithReceiveEth));

        merkleBase.withdrawFees(receiveEth);

        // It should set the ETH balance to 0.
        assertEq(address(merkleBase).balance, 0, "merkle lockup eth balance");
        // It should transfer fee collected in ETH to the provided address.
        assertEq(receiveEth.balance, defaults.DEFAULT_FEE(), "eth balance");
    }
}
