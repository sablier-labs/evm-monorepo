// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierFlowBase } from "src/interfaces/ISablierFlowBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Shared_Integration_Concrete_Test } from "../Concrete.t.sol";

contract CollectFees_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function setUp() public override {
        Shared_Integration_Concrete_Test.setUp();
        depositToDefaultStream();

        // Make a withdrawal and pay the fee.
        flow.withdrawMax{ value: FEE }({ streamId: defaultStreamId, to: users.recipient });

        setMsgSender({ msgSender: users.admin });
    }

    function test_GivenAdminIsNotContract() external {
        _test_CollectFees(users.admin);
    }

    function test_RevertGiven_AdminDoesNotImplementReceiveFunction() external givenAdminIsContract {
        // Transfer the admin to a contract that does not implement the receive function.
        flow.transferAdmin(address(contractWithoutReceive));

        // Make the contract the caller.
        setMsgSender({ msgSender: address(contractWithoutReceive) });

        // Expect a revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlowBase_FeeTransferFail.selector, address(contractWithoutReceive), address(flow).balance
            )
        );

        // Collect the fees.
        flow.collectFees();
    }

    function test_GivenAdminImplementsReceiveFunction() external givenAdminIsContract {
        // Transfer the admin to a contract that implements the receive function.
        flow.transferAdmin(address(contractWithReceive));

        // Make the contract the caller.
        setMsgSender({ msgSender: address(contractWithReceive) });

        // Run the tests.
        _test_CollectFees(address(contractWithReceive));
    }

    function _test_CollectFees(address admin) private {
        vm.warp({ newTimestamp: WITHDRAW_TIME });

        // Load the initial ETH balance of the admin.
        uint256 initialAdminBalance = admin.balance;

        // It should emit a {CollectFees} event.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlowBase.CollectFees({ admin: admin, feeAmount: FEE });

        flow.collectFees();

        // It should transfer the fee.
        assertEq(admin.balance, initialAdminBalance + FEE, "admin ETH balance");

        // It should decrease contract balance to zero.
        assertEq(address(flow).balance, 0, "flow ETH balance");
    }
}
