// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./Lockup.t.sol";

abstract contract StreamedAmountOf_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        defaultStreamId = createDefaultStream();
    }

    modifier givenCliffTimeInPast() {
        _;
    }

    modifier givenEndTimeInFuture() {
        _;
    }

    modifier givenNotCanceledStream() {
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenPENDINGStatus() {
        _;
    }

    modifier givenStartTimeInPast() {
        _;
    }

    modifier givenSTREAMINGStatus() {
        _;
    }
}
