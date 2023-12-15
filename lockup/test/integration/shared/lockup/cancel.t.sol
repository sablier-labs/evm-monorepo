// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./Lockup.t.sol";

abstract contract Cancel_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        defaultStreamId = createDefaultStream();
        changePrank({ msgSender: users.sender });
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenStreamCold() {
        _;
    }

    modifier givenStreamWarm() {
        _;
    }

    modifier whenCallerUnauthorized() {
        _;
    }

    modifier whenCallerAuthorized() {
        _;
    }

    modifier givenStreamCancelable() {
        _;
    }

    /// @dev In the LockupLinear contract, the streaming starts after the cliff time, whereas in the LockupDynamic
    /// contract, the streaming starts after the start time.
    modifier givenStatusStreaming() {
        // Warp to the future, after the stream's start time but before the stream's end time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });
        _;
    }

    modifier givenRecipientContract() {
        _;
    }

    modifier givenRecipientImplementsHook() {
        _;
    }

    modifier whenRecipientDoesNotRevert() {
        _;
    }

    modifier whenNoRecipientReentrancy() {
        _;
    }
}
