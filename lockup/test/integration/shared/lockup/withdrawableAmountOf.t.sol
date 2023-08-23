// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./Lockup.t.sol";

abstract contract WithdrawableAmountOf_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override { }

    modifier givenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    modifier givenStreamHasBeenCanceled() {
        _;
    }

    modifier givenStreamHasNotBeenCanceled() {
        _;
    }

    modifier givenStatusStreaming() {
        _;
    }
}
