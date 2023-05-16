// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Shared_Test } from "../Lockup.t.sol";

abstract contract Cancel_Shared_Test is Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        defaultStreamId = createDefaultStream();
        changePrank({ msgSender: users.recipient });
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    modifier whenNotNull() {
        _;
    }

    modifier whenStreamCold() {
        _;
    }

    modifier whenStreamWarm() {
        _;
    }

    modifier whenCallerUnauthorized() {
        _;
    }

    modifier whenCallerAuthorized() {
        _;
    }

    modifier whenStreamCancelable() {
        _;
    }

    /// @dev In the linear contract, the streaming starts after the cliff time, whereas in the dynamic contract,
    /// the streaming starts after the start time.
    modifier whenStatusStreaming() {
        // Warp to the future, after the stream's start time but before the stream's end time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });
        _;
    }

    modifier whenCallerSender() {
        changePrank({ msgSender: users.sender });
        _;
    }

    modifier whenRecipientContract() {
        _;
    }

    modifier whenRecipientImplementsHook() {
        _;
    }

    modifier whenRecipientDoesNotRevert() {
        _;
    }

    modifier whenNoRecipientReentrancy() {
        _;
    }

    modifier whenCallerRecipient() {
        changePrank({ msgSender: users.recipient });
        _;
    }

    modifier whenSenderContract() {
        _;
    }

    modifier whenSenderImplementsHook() {
        _;
    }

    modifier whenSenderDoesNotRevert() {
        _;
    }

    modifier whenNoSenderReentrancy() {
        _;
    }
}
