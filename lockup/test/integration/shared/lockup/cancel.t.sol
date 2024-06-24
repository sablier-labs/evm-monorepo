// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./Lockup.t.sol";

abstract contract Cancel_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        defaultStreamId = createDefaultStream();
        resetPrank({ msgSender: users.sender });
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenRecipientAllowedToHook() {
        _;
    }

    /// @dev In LockupLinear, the streaming starts after the cliff time, whereas in LockupDynamic, the streaming starts
    /// after the start time.
    modifier givenStatusStreaming() {
        // Warp to the future, after the stream's start time but before the stream's end time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        _;
    }

    modifier givenStreamCancelable() {
        _;
    }

    modifier givenStreamCold() {
        _;
    }

    modifier givenStreamWarm() {
        _;
    }

    modifier whenCallerAuthorized() {
        _;
    }

    modifier whenCallerUnauthorized() {
        _;
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    modifier whenRecipientNotReentrant() {
        _;
    }

    modifier whenRecipientNotReverting() {
        _;
    }

    modifier whenRecipientReturnsSelector() {
        _;
    }
}
