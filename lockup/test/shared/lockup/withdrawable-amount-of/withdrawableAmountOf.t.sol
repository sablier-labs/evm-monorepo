// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Shared_Test } from "../Lockup.t.sol";

abstract contract WithdrawableAmountOf_Shared_Test is Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override { }

    modifier whenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    modifier whenStreamHasBeenCanceled() {
        _;
    }

    modifier whenStreamHasNotBeenCanceled() {
        _;
    }

    modifier whenStatusStreaming() {
        _;
    }
}
