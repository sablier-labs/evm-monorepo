// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./Lockup.t.sol";

abstract contract Withdraw_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;
    address internal caller;

    function setUp() public virtual override {
        defaultStreamId = createDefaultStream();
        resetPrank({ msgSender: users.recipient });
    }

    modifier givenEndTimeInFuture() {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        _;
    }

    modifier givenNotCanceledStream() {
        _;
    }

    modifier givenNotDEPLETEDStatus() {
        vm.warp({ newTimestamp: defaults.START_TIME() });
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenRecipientAllowedToHook() {
        _;
    }

    modifier whenCallerRecipient() {
        _;
    }

    modifier whenCallerSender() {
        resetPrank({ msgSender: users.sender });
        _;
    }

    modifier whenHookReturnsValidSelector() {
        _;
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenNonRevertingRecipient() {
        _;
    }

    modifier whenNonZeroWithdrawAmount() {
        _;
    }

    modifier whenWithdrawalAddressNotZero() {
        _;
    }

    modifier whenWithdrawalAddressRecipient() {
        _;
    }

    modifier whenWithdrawAmountDoesNotOverdraw() {
        _;
    }
}
