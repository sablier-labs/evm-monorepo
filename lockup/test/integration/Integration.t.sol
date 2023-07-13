// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../Base.t.sol";
import { FaultyFlashLoanReceiver } from "../mocks/flash-loan/FaultyFlashLoanReceiver.sol";
import { ReentrantFlashLoanReceiver } from "../mocks/flash-loan/ReentrantFlashLoanReceiver.sol";
import { ReentrantRecipient } from "../mocks/hooks/ReentrantRecipient.sol";
import { ReentrantSender } from "../mocks/hooks/ReentrantSender.sol";
import { RevertingRecipient } from "../mocks/hooks/RevertingRecipient.sol";
import { RevertingSender } from "../mocks/hooks/RevertingSender.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    FaultyFlashLoanReceiver internal faultyFlashLoanReceiver = new FaultyFlashLoanReceiver();
    ReentrantFlashLoanReceiver internal reentrantFlashLoanReceiver = new ReentrantFlashLoanReceiver();
    ReentrantRecipient internal reentrantRecipient = new ReentrantRecipient();
    ReentrantSender internal reentrantSender = new ReentrantSender();
    RevertingRecipient internal revertingRecipient = new RevertingRecipient();
    RevertingSender internal revertingSender = new RevertingSender();

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy V2 Core.
        deployCoreConditionally();

        // Label the contracts.
        labelContracts();

        // Make the Admin the default caller in this test suite.
        vm.startPrank({ msgSender: users.admin });

        // Approve V2 Core to spend assets from the users.
        approveProtocol();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Labels the most relevant contracts.
    function labelContracts() internal {
        vm.label({ account: address(faultyFlashLoanReceiver), newLabel: "Faulty Flash Loan Receiver" });
        vm.label({ account: address(reentrantFlashLoanReceiver), newLabel: "Reentrant Flash Loan Receiver" });
        vm.label({ account: address(reentrantRecipient), newLabel: "Reentrant Lockup Recipient" });
        vm.label({ account: address(reentrantSender), newLabel: "Reentrant Lockup Sender" });
        vm.label({ account: address(revertingRecipient), newLabel: "Reverting Lockup Recipient" });
        vm.label({ account: address(revertingSender), newLabel: "Reverting Lockup Sender" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    EXPECT CALLS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a delegate call error.
    function expectRevertDueToDelegateCall(bool success, bytes memory returnData) internal {
        assertFalse(success, "delegatecall success");
        assertEq(returnData, abi.encodeWithSelector(Errors.DelegateCall.selector), "delegatecall return data");
    }
}
