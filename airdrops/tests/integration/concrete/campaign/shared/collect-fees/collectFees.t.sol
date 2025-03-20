// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract CollectFees_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotFactory() external {
        // Set the caller to anything other than the factory.
        resetPrank(users.admin);

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

        resetPrank(address(factoryMerkleBase));
        _;
    }

    function test_WhenFactoryAdminIsNotContract() external whenCallerFactory {
        _test_CollectFees(users.admin);
    }

    function test_RevertWhen_FactoryAdminDoesNotImplementReceiveFunction()
        external
        whenCallerFactory
        whenFactoryAdminIsContract
    {
        // Transfer the admin to a contract that implements the receive function.
        resetPrank({ msgSender: users.admin });
        factoryMerkleBase.transferAdmin(address(contractWithoutReceive));

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_FeeTransferFail.selector,
                address(contractWithoutReceive),
                address(merkleBase).balance
            )
        );

        resetPrank(address(factoryMerkleBase));
        merkleBase.collectFees(address(contractWithoutReceive));
    }

    function test_WhenFactoryAdminImplementsReceiveFunction() external whenCallerFactory whenFactoryAdminIsContract {
        // Transfer the admin to a contract that implements the receive function.
        resetPrank({ msgSender: users.admin });
        factoryMerkleBase.transferAdmin(address(contractWithoutReceive));

        _test_CollectFees(address(contractWithReceive));
    }

    function _test_CollectFees(address admin) private {
        // Load the initial ETH balance of the admin.
        uint256 initialAdminBalance = admin.balance;

        resetPrank(address(factoryMerkleBase));
        merkleBase.collectFees(admin);

        // It should set the ETH balance to 0.
        assertEq(address(merkleBase).balance, 0, "merkle lockup ETH balance");
        // It should transfer fee collected in ETH to the factory admin.
        assertEq(admin.balance, initialAdminBalance + MIN_FEE_WEI, "admin ETH balance");
    }
}
