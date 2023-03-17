// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Linear_Unit_Test } from "../Linear.t.sol";

contract StreamedAmountOf_Linear_Unit_Test is Linear_Unit_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        Linear_Unit_Test.setUp();

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier whenStreamNotActive() {
        _;
    }

    /// @dev it should return zero.
    function test_StreamedAmountOf_StreamNull() external whenStreamNotActive {
        uint256 nullStreamId = 1729;
        uint128 actualStreamedAmount = linear.streamedAmountOf(nullStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev it should return zero.
    function test_StreamedAmountOf_StreamCanceled() external whenStreamNotActive {
        lockup.cancel(defaultStreamId);
        uint256 actualStreamedAmount = linear.streamedAmountOf(defaultStreamId);
        uint256 expectedStreamedAmount = linear.getWithdrawnAmount(defaultStreamId);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev it should return the withdrawn amount.
    function test_StreamedAmountOf_StreamDepleted() external whenStreamNotActive {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        uint128 withdrawAmount = DEFAULT_DEPOSIT_AMOUNT;
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });
        uint256 actualStreamedAmount = linear.streamedAmountOf(defaultStreamId);
        uint256 expectedStreamedAmount = withdrawAmount;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier whenStreamActive() {
        _;
    }

    /// @dev it should return zero.
    function test_StreamedAmountOf_CliffTimeGreaterThanCurrentTime() external whenStreamActive {
        uint128 actualStreamedAmount = linear.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier whenCliffTimeLessThanOrEqualToCurrentTime() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    function test_StreamedAmountOf() external whenStreamActive whenCliffTimeLessThanOrEqualToCurrentTime {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint128 actualStreamedAmount = linear.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 2_600e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
