// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./Lockup.t.sol";

abstract contract Withdraw_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        defaultStreamId = createDefaultStream();
        resetPrank({ msgSender: users.recipient });
    }

    modifier givenEndTimeInTheFuture() {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenRecipientAllowedToHook() {
        _;
    }

    modifier givenStreamNotDepleted() {
        vm.warp({ newTimestamp: defaults.START_TIME() });
        _;
    }

    modifier whenCallerRecipient() {
        _;
    }

    modifier whenCallerSender() {
        resetPrank({ msgSender: users.sender });
        _;
    }

    modifier whenNoOverdraw() {
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

    modifier whenStreamHasNotBeenCanceled() {
        _;
    }

    modifier whenToNonZeroAddress() {
        _;
    }

    modifier whenWithdrawalAddressIsRecipient() {
        _;
    }

    modifier whenWithdrawalAddressNotRecipient() {
        _;
    }

    modifier whenWithdrawAmountNotZero() {
        _;
    }
}
