// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as CoreErrors } from "src/core/libraries/Errors.sol";
import { ISablierMerkleBase } from "src/periphery/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/periphery/libraries/Errors.sol";

import { MerkleCampaign_Integration_Shared_Test } from "../../shared/MerkleCampaign.t.sol";

contract WithdrawFees_Integration_Test is MerkleCampaign_Integration_Shared_Test {
    function setUp() public virtual override {
        MerkleCampaign_Integration_Shared_Test.setUp();

        // Set the `merkleBase` to the merkleLL contract to use it in the tests.
        merkleBase = ISablierMerkleBase(merkleLL);

        // Claim to collect some fees.
        resetPrank(users.recipient);
        claim();
    }

    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank(users.eve);

        vm.expectRevert(abi.encodeWithSelector(CoreErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactory.withdrawFees(users.eve, merkleBase);
    }

    function test_RevertWhen_WithdrawalAddressZero() external whenCallerAdmin {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleFactory_WithdrawToZeroAddress.selector));
        merkleFactory.withdrawFees(payable(address(0)), merkleBase);
    }

    modifier whenWithdrawalAddressNotZero() {
        _;
    }

    function test_RevertWhen_ProvidedMerkleLockupNotValid() external whenCallerAdmin whenWithdrawalAddressNotZero {
        vm.expectRevert();
        merkleFactory.withdrawFees(users.eve, ISablierMerkleBase(users.eve));
    }

    modifier whenProvidedMerkleLockupValid() {
        _;
    }

    function test_WhenProvidedAddressNotContract() external whenCallerAdmin whenProvidedMerkleLockupValid {
        uint256 previousToBalance = users.eve.balance;

        // It should emit {WithdrawSablierFees} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit WithdrawSablierFees({
            admin: users.admin,
            merkleBase: merkleBase,
            to: users.eve,
            sablierFees: defaults.DEFAULT_SABLIER_FEE()
        });

        merkleFactory.withdrawFees(users.eve, merkleBase);

        // It should set the ETH balance to 0.
        assertEq(address(merkleBase).balance, 0, "merkle lockup eth balance");
        // It should transfer fee collected in ETH to the provided address.
        assertEq(users.eve.balance, previousToBalance + defaults.DEFAULT_SABLIER_FEE(), "eth balance");
    }

    modifier whenProvidedAddressContract() {
        _;
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

        // It should emit {WithdrawSablierFees} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit WithdrawSablierFees({
            admin: users.admin,
            merkleBase: merkleBase,
            to: receiveEth,
            sablierFees: defaults.DEFAULT_SABLIER_FEE()
        });

        merkleFactory.withdrawFees(receiveEth, merkleBase);

        // It should set the ETH balance to 0.
        assertEq(address(merkleBase).balance, 0, "merkle lockup eth balance");
        // It should transfer fee collected in ETH to the provided address.
        assertEq(receiveEth.balance, defaults.DEFAULT_SABLIER_FEE(), "eth balance");
    }
}
