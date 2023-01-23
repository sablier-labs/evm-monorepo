// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Base_Test } from "../Base.t.sol";
import { Empty } from "../shared/hooks/Empty.t.sol";
import { FaultyFlashLoanReceiver } from "../shared/flash-loan/FaultyFlashLoanReceiver.t.sol";
import { GoodFlashLoanReceiver } from "../shared/flash-loan/GoodFlashLoanReceiver.t.sol";
import { ReentrantFlashLoanReceiver } from "../shared/flash-loan/ReentrantFlashLoanReceiver.t.sol";
import { GoodRecipient } from "../shared/hooks/GoodRecipient.t.sol";
import { GoodSender } from "../shared/hooks/GoodSender.t.sol";
import { ReentrantRecipient } from "../shared/hooks/ReentrantRecipient.t.sol";
import { ReentrantSender } from "../shared/hooks/ReentrantSender.t.sol";
import { RevertingRecipient } from "../shared/hooks/RevertingRecipient.t.sol";
import { RevertingSender } from "../shared/hooks/RevertingSender.t.sol";

/// @title Unit_Test
/// @notice Base unit test contract that contains common logic needed by all unit test contracts.
abstract contract Unit_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    Empty internal empty = new Empty();
    FaultyFlashLoanReceiver internal faultyFlashLoanReceiver = new FaultyFlashLoanReceiver();
    GoodFlashLoanReceiver internal goodFlashLoanReceiver = new GoodFlashLoanReceiver();
    GoodRecipient internal goodRecipient = new GoodRecipient();
    GoodSender internal goodSender = new GoodSender();
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
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Label the test contracts.
    function labelTestContracts() internal {
        vm.label({ account: address(empty), newLabel: "Empty" });
        vm.label({ account: address(DEFAULT_ASSET), newLabel: "Dai" });
        vm.label({ account: address(faultyFlashLoanReceiver), newLabel: "Faulty Flash Loan Receiver" });
        vm.label({ account: address(goodFlashLoanReceiver), newLabel: "Good Flash Loan Receiver" });
        vm.label({ account: address(goodRecipient), newLabel: "Good Recipient" });
        vm.label({ account: address(goodSender), newLabel: "Good Sender" });
        vm.label({ account: address(nonCompliantAsset), newLabel: "Non-Compliant ERC-20 Asset" });
        vm.label({ account: address(reentrantFlashLoanReceiver), newLabel: "Reentrant Flash Loan Receiver" });
        vm.label({ account: address(goodFlashLoanReceiver), newLabel: "Good Flash Loan Receiver" });
        vm.label({ account: address(reentrantRecipient), newLabel: "Reentrant Recipient" });
        vm.label({ account: address(reentrantSender), newLabel: "Reentrant Sender" });
        vm.label({ account: address(revertingRecipient), newLabel: "Reverting Recipient" });
        vm.label({ account: address(revertingSender), newLabel: "Reverting Sender" });
    }
}
