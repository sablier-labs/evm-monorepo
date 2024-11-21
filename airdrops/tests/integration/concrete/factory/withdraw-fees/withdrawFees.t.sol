// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract WithdrawFees_Integration_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Set the `merkleBase` to the merkleLL contract to use it in the tests.
        merkleBase = ISablierMerkleBase(merkleLL);

        // Claim to collect some fees.
        resetPrank(users.recipient);
        claim();
    }

    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank(users.eve);

        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactory.withdrawFees(users.eve, merkleBase);
    }

    function test_RevertWhen_WithdrawalAddressZero() external whenCallerAdmin {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleFactory_WithdrawToZeroAddress.selector));
        merkleFactory.withdrawFees(payable(address(0)), merkleBase);
    }

    function test_RevertWhen_ProvidedMerkleLockupNotValid() external whenCallerAdmin whenWithdrawalAddressNotZero {
        vm.expectRevert();
        merkleFactory.withdrawFees(users.eve, ISablierMerkleBase(users.eve));
    }

    function test_WhenProvidedAddressNotContract() external whenCallerAdmin whenProvidedMerkleLockupValid {
        uint256 previousToBalance = users.eve.balance;

        // It should emit {WithdrawFees} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.WithdrawFees({
            admin: users.admin,
            merkleBase: merkleBase,
            to: users.eve,
            fees: defaults.DEFAULT_FEE()
        });

        merkleFactory.withdrawFees(users.eve, merkleBase);

        // It should set the ETH balance to 0.
        assertEq(address(merkleBase).balance, 0, "merkle lockup eth balance");
        // It should transfer fee collected in ETH to the provided address.
        assertEq(users.eve.balance, previousToBalance + defaults.DEFAULT_FEE(), "eth balance");
    }

    function test_RevertWhen_ProvidedAddressNotImplementReceiveEth()
        external
        whenCallerAdmin
        whenProvidedMerkleLockupValid
        whenProvidedAddressContract
    {
        address payable noReceiveEth = payable(address(contractWithoutReceiveEth));
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_FeeWithdrawFailed.selector, noReceiveEth, address(merkleBase).balance
            )
        );
        merkleFactory.withdrawFees(noReceiveEth, merkleBase);
    }

    function test_WhenProvidedAddressImplementReceiveEth()
        external
        whenCallerAdmin
        whenProvidedMerkleLockupValid
        whenProvidedAddressContract
    {
        address payable receiveEth = payable(address(contractWithReceiveEth));

        // It should emit {WithdrawFees} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.WithdrawFees({
            admin: users.admin,
            merkleBase: merkleBase,
            to: receiveEth,
            fees: defaults.DEFAULT_FEE()
        });

        merkleFactory.withdrawFees(receiveEth, merkleBase);

        // It should set the ETH balance to 0.
        assertEq(address(merkleBase).balance, 0, "merkle lockup eth balance");
        // It should transfer fee collected in ETH to the provided address.
        assertEq(receiveEth.balance, defaults.DEFAULT_FEE(), "eth balance");
    }
}
