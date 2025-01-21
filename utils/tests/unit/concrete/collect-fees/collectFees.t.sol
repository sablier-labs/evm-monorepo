// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierFees } from "src/interfaces/ISablierFees.sol";
import { Errors } from "src/libraries/Errors.sol";

import { SablierFeesMock } from "tests/mocks/SablierFeesMock.sol";
import { Unit_Test } from "../../Unit.t.sol";

contract CollectFees_Unit_Concrete_Test is Unit_Test {
    SablierFeesMock internal sablierFeesMock;

    function setUp() public virtual override {
        Unit_Test.setUp();

        sablierFeesMock = new SablierFeesMock(admin);
    }

    function test_GivenAdminIsNotContract() external {
        _test_CollectFees(admin);
    }

    modifier givenAdminIsContract() {
        _;
    }

    function test_RevertGiven_AdminDoesNotImplementReceiveFunction() external givenAdminIsContract {
        // Transfer the admin to a contract that does not implement the receive function.
        resetPrank({ msgSender: admin });
        sablierFeesMock.transferAdmin(address(contractWithoutReceive));

        // Make the contract the caller.
        resetPrank({ msgSender: address(contractWithoutReceive) });

        // Expect a revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFees_FeeTransferFail.selector,
                address(contractWithoutReceive),
                address(sablierFeesMock).balance
            )
        );

        // Collect the fees.
        sablierFeesMock.collectFees();
    }

    function test_GivenAdminImplementsReceiveFunction() external givenAdminIsContract {
        // Transfer the admin to a contract that implements the receive function.
        resetPrank({ msgSender: admin });
        sablierFeesMock.transferAdmin(address(contractWithReceive));

        // Make the contract the caller.
        resetPrank({ msgSender: address(contractWithReceive) });

        // Run the tests.
        _test_CollectFees(address(contractWithReceive));
    }

    function _test_CollectFees(address admin) private {
        uint256 fee = 1 ether;

        // Set the contract balance to 1 ETH.
        vm.deal({ account: address(sablierFeesMock), newBalance: 1 ether });

        // Load the initial ETH balance of the admin.
        uint256 initialAdminBalance = admin.balance;

        // It should emit a {CollectFees} event.
        vm.expectEmit({ emitter: address(sablierFeesMock) });
        emit ISablierFees.CollectFees({ admin: admin, feeAmount: fee });

        sablierFeesMock.collectFees();

        // It should transfer the fee.
        assertEq(admin.balance, initialAdminBalance + fee, "admin ETH balance");

        // It should decrease contract balance to zero.
        assertEq(address(sablierFeesMock).balance, 0, "sablierFeesMock ETH balance");
    }
}
