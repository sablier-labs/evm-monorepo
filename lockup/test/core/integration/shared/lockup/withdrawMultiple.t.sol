// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../Integration.t.sol";

abstract contract WithdrawMultiple_Integration_Shared_Test is Integration_Test {
    address internal caller;
    uint40 internal earlyStopTime;
    uint40 internal originalTime;
    uint128[] internal testAmounts;
    uint256[] internal testStreamIds;

    function setUp() public virtual override {
        earlyStopTime = defaults.WARP_26_PERCENT();
        originalTime = getBlockTimestamp();
        createTestStreams();
    }

    /// @dev Creates the default streams used throughout the tests.
    function createTestStreams() internal {
        // Warp back to the original timestamp.
        vm.warp({ newTimestamp: originalTime });

        // Define the default amounts.
        testAmounts = new uint128[](3);
        testAmounts[0] = defaults.WITHDRAW_AMOUNT();
        testAmounts[1] = defaults.DEPOSIT_AMOUNT();
        testAmounts[2] = defaults.WITHDRAW_AMOUNT() / 2;

        // Create three test streams:
        // 1. A default stream
        // 2. A stream with an early end time
        // 3. A stream meant to be canceled before the withdrawal is made
        testStreamIds = new uint256[](3);
        testStreamIds[0] = createDefaultStream();
        testStreamIds[1] = createDefaultStreamWithEndTime(earlyStopTime);
        testStreamIds[2] = createDefaultStream();
    }

    /// @dev This modifier runs the test in three different modes:
    /// - Stream's sender as caller
    /// - Stream's recipient as caller
    /// - Approved NFT operator as caller
    modifier whenCallerAuthorizedAllStreams() {
        caller = users.sender;
        _;

        createTestStreams();
        caller = users.recipient;
        _;

        createTestStreams();
        caller = users.operator;
        _;
    }
}
