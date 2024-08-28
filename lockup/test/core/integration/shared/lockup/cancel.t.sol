// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./Lockup.t.sol";

abstract contract Cancel_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        defaultStreamId = createDefaultStream();
        resetPrank({ msgSender: users.sender });
    }

    modifier givenCancelableStream() {
        _;
    }

    modifier givenColdStream() {
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenRecipientAllowedToHook() {
        _;
    }

    /// @dev In LockupLinear, the streaming starts after the cliff time, whereas in LockupDynamic, the streaming starts
    /// after the start time.
    modifier givenSTREAMINGStatus() {
        // Warp to the future, after the stream's start time but before the stream's end time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        _;
    }

    modifier givenWarmStream() {
        _;
    }

    modifier whenAuthorizedCaller() {
        _;
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenNonRevertingRecipient() {
        _;
    }

    modifier whenRecipientNotReentrant() {
        _;
    }

    modifier whenRecipientReturnsValidSelector() {
        _;
    }

    modifier whenUnauthorizedCaller() {
        _;
    }
}
