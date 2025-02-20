// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract CollectFees_Integration_Test is Integration_Test {
    function test_RevertWhen_ProvidedMerkleLockupNotValid() external {
        vm.expectRevert();
        merkleFactoryBase.collectFees(ISablierMerkleBase(users.eve));
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
        resetPrank({ msgSender: users.admin });
        merkleFactoryBase.transferAdmin(address(contractWithoutReceiveEth));

        // Make the contract the caller.
        resetPrank({ msgSender: address(contractWithoutReceiveEth) });

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_FeeTransferFail.selector,
                address(contractWithoutReceiveEth),
                address(merkleBase).balance
            )
        );
        merkleFactoryBase.collectFees(merkleBase);
    }

    function test_WhenFactoryAdminImplementsReceiveFunction()
        external
        whenProvidedMerkleLockupValid
        whenFactoryAdminIsContract
    {
        // Transfer the admin to a contract that implements the receive function.
        resetPrank({ msgSender: users.admin });
        merkleFactoryBase.transferAdmin(address(contractWithReceiveEth));

        _test_CollectFees(address(contractWithReceiveEth));
    }

    function _test_CollectFees(address admin) private {
        // Load the initial ETH balance of the admin.
        uint256 initialAdminBalance = admin.balance;

        // It should emit a {CollectFees} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.CollectFees({ admin: admin, merkleBase: merkleBase, feeAmount: MINIMUM_FEE });

        // Make Alice the caller.
        resetPrank({ msgSender: users.eve });

        merkleFactoryBase.collectFees(merkleBase);

        // It should decrease merkle contract balance to zero.
        assertEq(address(merkleBase).balance, 0, "merkle lockup ETH balance");

        // It should transfer fee to the factory admin.
        assertEq(admin.balance, initialAdminBalance + MINIMUM_FEE, "admin ETH balance");
    }
}
