// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Broker } from "src/core/types/DataTypes.sol";

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

    uint256 internal defaultStreamId;
    uint256 internal notTransferableStreamId;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A test contract that is meant to be overridden by the implementing contract, which will be
    /// either {SablierLockupDynamic}, {SablierLockupLinear} or {SablierLockupTranched}.
    ISablierLockup internal lockup;

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
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    EXPECT CALLS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a delegate call error.
    function expectRevertDueToDelegateCall(bool success, bytes memory returnData) internal pure {
        assertFalse(success, "delegatecall success");
        assertEq(returnData, abi.encodeWithSelector(Errors.DelegateCall.selector), "delegatecall return data");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates the default stream.
    function createDefaultStream() internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream but make it not cancelable.
    function createDefaultStreamNotCancelable() internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the NFT transfer disabled.
    function createDefaultStreamNotTransferable() internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided address.
    function createDefaultStreamWithAsset(IERC20 asset) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided broker.
    function createDefaultStreamWithBroker(Broker memory broker) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided end time.
    function createDefaultStreamWithEndTime(uint40 endTime) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided user as the recipient and the sender.
    function createDefaultStreamWithIdenticalUsers(address user) internal returns (uint256 streamId) {
        return createDefaultStreamWithUsers({ recipient: user, sender: user });
    }

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided start time.
    function createDefaultStreamWithStartTime(uint40 startTime) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided total amount.
    function createDefaultStreamWithTotalAmount(uint128 totalAmount) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided sender and recipient.
    function createDefaultStreamWithUsers(
        address recipient,
        address sender
    )
        internal
        virtual
        returns (uint256 streamId);
}
