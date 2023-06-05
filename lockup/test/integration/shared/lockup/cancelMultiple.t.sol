// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./Lockup.t.sol";

abstract contract CancelMultiple_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    uint40 internal originalTime;
    uint256[] internal testStreamIds;

    function setUp() public virtual override {
        originalTime = getBlockTimestamp();
        createTestStreams();
    }

    /// @dev Creates the default streams used throughout the tests.
    function createTestStreams() internal {
        // Warp back to the original timestamp.
        vm.warp({ timestamp: originalTime });

        // Create the test streams.
        testStreamIds = new uint256[](2);
        testStreamIds[0] = createDefaultStream();
        // Create a stream with an end time double that of the default stream so that the refund amounts are different.
        testStreamIds[1] = createDefaultStreamWithEndTime(defaults.END_TIME() + defaults.TOTAL_DURATION());
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    modifier whenArrayCountNotZero() {
        _;
    }

    modifier whenNoNull() {
        _;
    }

    modifier whenAllStreamsWarm() {
        _;
    }

    modifier whenCallerUnauthorized() {
        _;
    }

    modifier whenCallerAuthorizedAllStreams() {
        _;
        vm.warp({ timestamp: originalTime });
        createTestStreams();
        changePrank({ msgSender: users.recipient });
        _;
    }

    modifier whenAllStreamsCancelable() {
        _;
    }
}
