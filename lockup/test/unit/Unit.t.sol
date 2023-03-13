// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Base_Test } from "../Base.t.sol";
import { Empty } from "../shared/mockups/hooks/Empty.t.sol";
import { FaultyFlashLoanReceiver } from "../shared/mockups/flash-loan/FaultyFlashLoanReceiver.t.sol";
import { ReentrantFlashLoanReceiver } from "../shared/mockups/flash-loan/ReentrantFlashLoanReceiver.t.sol";
import { ReentrantRecipient } from "../shared/mockups/hooks/ReentrantRecipient.t.sol";
import { ReentrantSender } from "../shared/mockups/hooks/ReentrantSender.t.sol";
import { RevertingRecipient } from "../shared/mockups/hooks/RevertingRecipient.t.sol";
import { RevertingSender } from "../shared/mockups/hooks/RevertingSender.t.sol";

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
        deployProtocol();

        // Make the admin the default caller in this test suite.
        vm.startPrank({ msgSender: users.admin });

        // Approve all protocol contracts to spend ERC-20 assets from the users.
        approveProtocol();

        // Label the test contracts.
        labelTestContracts();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

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
