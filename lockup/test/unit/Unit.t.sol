// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../Base.t.sol";
import { Empty } from "../mocks/hooks/Empty.sol";
import { FaultyFlashLoanReceiver } from "../mocks/flash-loan/FaultyFlashLoanReceiver.sol";
import { ReentrantFlashLoanReceiver } from "../mocks/flash-loan/ReentrantFlashLoanReceiver.sol";
import { ReentrantRecipient } from "../mocks/hooks/ReentrantRecipient.sol";
import { ReentrantSender } from "../mocks/hooks/ReentrantSender.sol";
import { RevertingRecipient } from "../mocks/hooks/RevertingRecipient.sol";
import { RevertingSender } from "../mocks/hooks/RevertingSender.sol";

/// @title Unit_Test
/// @notice Base unit test contract with common logic needed by all unit test contracts.
abstract contract Unit_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    Empty internal empty = new Empty();
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

        // Deploy the entire protocol.
        deployProtocolConditionally();

        // Make the admin the default caller in this test suite.
        vm.startPrank({ msgSender: users.admin });

        // Approve all protocol contracts to spend assets from the users.
        approveProtocol();

        // Label the test contracts.
        labelTestContracts();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a delegate call error.
    function expectRevertDueToDelegateCall(bool success, bytes memory returnData) internal {
        assertFalse(success, "delegatecall success");
        assertEq(returnData, abi.encodeWithSelector(Errors.DelegateCall.selector), "delegatecall return data");
    }

    /// @dev Label the test contracts.
    function labelTestContracts() internal {
        vm.label({ account: address(empty), newLabel: "Empty" });
        vm.label({ account: address(faultyFlashLoanReceiver), newLabel: "Faulty Flash Loan Receiver" });
        vm.label({ account: address(nonCompliantAsset), newLabel: "Non-Compliant ERC-20 Asset" });
        vm.label({ account: address(reentrantFlashLoanReceiver), newLabel: "Reentrant Flash Loan Receiver" });
        vm.label({ account: address(reentrantRecipient), newLabel: "Reentrant Lockup Recipient" });
        vm.label({ account: address(reentrantSender), newLabel: "Reentrant Lockup Sender" });
        vm.label({ account: address(revertingRecipient), newLabel: "Reverting Lockup Recipient" });
        vm.label({ account: address(revertingSender), newLabel: "Reverting Lockup Sender" });
    }
}
