// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Base_Test } from "../Base.t.sol";
import { GoodFlashLoanReceiver } from "../helpers/flash-loan/GoodFlashLoanReceiver.t.sol";
import { GoodRecipient } from "../helpers/hooks/GoodRecipient.t.sol";
import { GoodSender } from "../helpers/hooks/GoodSender.t.sol";

/// @title Fuzz_Test
/// @notice Base fuzz test contract that contains common logic needed by all fuzz test contracts.
abstract contract Fuzz_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    GoodFlashLoanReceiver internal goodFlashLoanReceiver = new GoodFlashLoanReceiver();
    GoodRecipient internal goodRecipient = new GoodRecipient();
    GoodSender internal goodSender = new GoodSender();

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
        vm.label({ account: address(goodFlashLoanReceiver), newLabel: "Good Flash Loan Receiver" });
    }
}
