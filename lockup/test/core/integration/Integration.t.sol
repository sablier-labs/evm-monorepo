// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";

import { Base_Test } from "../../Base.t.sol";
import {
    RecipientInterfaceIDIncorrect,
    RecipientInterfaceIDMissing,
    RecipientInvalidSelector,
    RecipientReentrant,
    RecipientReverting
} from "../../mocks/Hooks.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    // Various stream IDs to be used across the tests.
    // An array of stream IDs to be canceled.
    uint256[] internal cancelMultipleStreamIds;
    // Default stream ID.
    uint256 internal defaultStreamId;
    // A stream ID with a different sender and recipient.
    uint256 internal differentSenderRecipientStreamId;
    // A stream ID with an early end time.
    uint256 internal earlyEndtimeStreamId;
    // A stream ID with the same sender and recipient.
    uint256 internal identicalSenderRecipientStreamId;
    // A non-cancelable stream ID.
    uint256 internal notCancelableStreamId;
    // A non-transferable stream ID.
    uint256 internal notTransferableStreamId;
    // A stream ID that does not exist.
    uint256 internal nullStreamId = 1729;
    // A stream with a recipient contract that implements {ISablierLockupRecipient}.
    uint256 internal recipientGoodStreamId;
    // A stream with a recipient contract that returns invalid selector bytes on the hook call.
    uint256 internal recipientInvalidSelectorStreamId;
    // A stream with a reentrant contract as the recipient.
    uint256 internal recipientReentrantStreamId;
    // Astream with a reverting contract as the stream's recipient.
    uint256 internal recipientRevertStreamId;
    // An array of stream IDs to be withdrawn from.
    uint256[] internal withdrawMultipleStreamIds;

    // An array of amounts to be used in `withdrawMultiple` tests.
    uint128[] internal withdrawAmounts;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    RecipientInterfaceIDIncorrect internal recipientInterfaceIDIncorrect;
    RecipientInterfaceIDMissing internal recipientInterfaceIDMissing;
    RecipientInvalidSelector internal recipientInvalidSelector;
    RecipientReentrant internal recipientReentrant;
    RecipientReverting internal recipientReverting;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        recipientInterfaceIDIncorrect = new RecipientInterfaceIDIncorrect();
        recipientInterfaceIDMissing = new RecipientInterfaceIDMissing();
        recipientInvalidSelector = new RecipientInvalidSelector();
        recipientReentrant = new RecipientReentrant();
        recipientReverting = new RecipientReverting();
        vm.label({ account: address(recipientInterfaceIDIncorrect), newLabel: "Recipient Interface ID Incorrect" });
        vm.label({ account: address(recipientInterfaceIDMissing), newLabel: "Recipient Interface ID Missing" });
        vm.label({ account: address(recipientInvalidSelector), newLabel: "Recipient Invalid Selector" });
        vm.label({ account: address(recipientReentrant), newLabel: "Recipient Reentrant" });
        vm.label({ account: address(recipientReverting), newLabel: "Recipient Reverting" });

        withdrawAmounts.push(defaults.WITHDRAW_AMOUNT());
        withdrawAmounts.push(defaults.DEPOSIT_AMOUNT());
        withdrawAmounts.push(defaults.WITHDRAW_AMOUNT() / 2);
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
