// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../Base.t.sol";
import {
    RecipientInterfaceIDIncorrect,
    RecipientInterfaceIDMissing,
    RecipientInvalidSelector,
    RecipientReentrant,
    RecipientReverting
} from "../mocks/Hooks.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.

abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    RecipientInterfaceIDIncorrect internal recipientInterfaceIDIncorrect = new RecipientInterfaceIDIncorrect();
    RecipientInterfaceIDMissing internal recipientInterfaceIDMissing = new RecipientInterfaceIDMissing();
    RecipientInvalidSelector internal recipientInvalidSelector = new RecipientInvalidSelector();
    RecipientReentrant internal recipientReentrant = new RecipientReentrant();
    RecipientReverting internal recipientReverting = new RecipientReverting();

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Label the contracts.
        labelContracts();

        // Make the Admin the default caller in this test suite.
        resetPrank({ msgSender: users.admin });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Labels the most relevant contracts.
    function labelContracts() internal {
        vm.label({ account: address(recipientInterfaceIDIncorrect), newLabel: "Recipient Interface ID Incorrect" });
        vm.label({ account: address(recipientInterfaceIDMissing), newLabel: "Recipient Interface ID Missing" });
        vm.label({ account: address(recipientInvalidSelector), newLabel: "Recipient Invalid Selector" });
        vm.label({ account: address(recipientReentrant), newLabel: "Recipient Reentrant" });
        vm.label({ account: address(recipientReverting), newLabel: "Recipient Reverting" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    EXPECT CALLS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a delegate call error.
    function expectRevertDueToDelegateCall(bool success, bytes memory returnData) internal pure {
        assertFalse(success, "delegatecall success");
        assertEq(returnData, abi.encodeWithSelector(Errors.DelegateCall.selector), "delegatecall return data");
    }
}
