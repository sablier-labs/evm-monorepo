// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract CollectFees_Integration_Test is Integration_Test {
    function test_RevertWhen_ProvidedMerkleLockupNotValid() external {
        vm.expectRevert();
        factoryMerkleBase.collectFees(ISablierMerkleBase(users.eve));
    }

    function test_WhenFactoryAdminIsNotContract() external whenProvidedMerkleLockupValid {
        _test_CollectFees(users.admin);
    }

    function test_RevertWhen_FactoryAdminDoesNotImplementReceiveFunction()
        external
        whenProvidedMerkleLockupValid
        whenFactoryAdminIsContract
    {
        // Transfer the admin to a contract that does not implement the receive function.
        setMsgSender(users.admin);
        factoryMerkleBase.transferAdmin(address(contractWithoutReceive));

        // Make the contract the caller.
        setMsgSender(address(contractWithoutReceive));

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_FeeTransferFail.selector,
                address(contractWithoutReceive),
                address(merkleBase).balance
            )
        );
        factoryMerkleBase.collectFees(merkleBase);
    }

    function test_WhenFactoryAdminImplementsReceiveFunction()
        external
        whenProvidedMerkleLockupValid
        whenFactoryAdminIsContract
    {
        // Transfer the admin to a contract that implements the receive function.
        setMsgSender(users.admin);
        factoryMerkleBase.transferAdmin(address(contractWithReceive));

        _test_CollectFees(address(contractWithReceive));
    }

    function _test_CollectFees(address admin) private {
        // Load the initial ETH balance of the admin.
        uint256 initialAdminBalance = admin.balance;

        // It should emit a {CollectFees} event.
        vm.expectEmit({ emitter: address(factoryMerkleBase) });
        emit ISablierFactoryMerkleBase.CollectFees({ admin: admin, campaign: merkleBase, feeAmount: MIN_FEE_WEI });

        // Make Alice the caller.
        setMsgSender(users.eve);

        factoryMerkleBase.collectFees(merkleBase);

        // It should decrease merkle contract balance to zero.
        assertEq(address(merkleBase).balance, 0, "merkle lockup ETH balance");

        // It should transfer fee to the factory admin.
        assertEq(admin.balance, initialAdminBalance + MIN_FEE_WEI, "admin ETH balance");
    }
}
