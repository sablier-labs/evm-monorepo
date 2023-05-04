// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";

abstract contract WithdrawMultiple_Shared_Test is Lockup_Shared_Test {
    uint40 internal EARLY_STOP_TIME;
    address internal caller;
    uint128[] internal testAmounts;
    uint256[] internal testStreamIds;

    function setUp() public virtual override {
        EARLY_STOP_TIME = defaults.WARP_26_PERCENT();
        createTestStreams();
    }

    /// @dev Creates the default streams used throughout the tests.
    function createTestStreams() internal {
        // Warp back to the original timestamp.
        vm.warp({ timestamp: MARCH_1_2023 });

        // Define the default amounts.
        testAmounts = new uint128[](3);
        testAmounts[0] = defaults.WITHDRAW_AMOUNT();
        testAmounts[1] = defaults.DEPOSIT_AMOUNT();
        testAmounts[2] = defaults.WITHDRAW_AMOUNT() / 2;

        // Create three streams:
        // 1. A default stream
        // 2. A stream with an early end time
        // 3. A stream meant to be canceled before the withdrawal is made
        testStreamIds = new uint256[](3);
        testStreamIds[0] = createDefaultStream();
        testStreamIds[1] = createDefaultStreamWithEndTime(EARLY_STOP_TIME);
        testStreamIds[2] = createDefaultStream();
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenToNonZeroAddress() {
        _;
    }

    modifier whenArraysEqual() {
        _;
    }

    modifier whenNoNull() {
        _;
    }

    modifier whenNoStatusPendingOrDepleted() {
        _;
    }

    modifier whenCallerUnauthorized() {
        _;
    }

    /// @dev This modifier runs the test in three different modes:
    /// - Stream's sender as caller
    /// - Stream's recipient as caller
    /// - Approved NFT operator as caller
    modifier whenCallerAuthorizedAllStreams() {
        caller = users.sender;
        _;
        caller = users.recipient;
        vm.warp({ timestamp: MARCH_1_2023 });
        _;
        caller = users.operator;
        vm.warp({ timestamp: MARCH_1_2023 });
        changePrank({ msgSender: users.recipient });
        lockup.setApprovalForAll({ operator: users.operator, _approved: true });
        _;
    }

    modifier whenNoAmountZero() {
        _;
    }

    modifier whenNoAmountOverdraws() {
        _;
    }
}
