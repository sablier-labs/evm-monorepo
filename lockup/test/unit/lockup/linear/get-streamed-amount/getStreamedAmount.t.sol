// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Linear_Unit_Test } from "../Linear.t.sol";

contract GetStreamedAmount_Linear_Unit_Test is Linear_Unit_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        Linear_Unit_Test.setUp();

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier streamNotActive() {
        _;
    }

    /// @dev it should return zero.
    function test_GetStreamedAmount_StreamNull() external streamNotActive {
        uint256 nullStreamId = 1729;
        uint128 actualStreamedAmount = linear.getStreamedAmount(nullStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev it should return zero.
    function test_GetStreamedAmount_StreamCanceled() external streamNotActive {
        lockup.cancel(defaultStreamId);
        uint256 actualStreamedAmount = linear.getStreamedAmount(defaultStreamId);
        uint256 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev it should return the withdrawn amount.
    function test_GetStreamedAmount_StreamDepleted() external streamNotActive {
        vm.warp({ timestamp: DEFAULT_STOP_TIME });
        uint128 withdrawAmount = DEFAULT_NET_DEPOSIT_AMOUNT;
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });
        uint256 actualStreamedAmount = linear.getStreamedAmount(defaultStreamId);
        uint256 expectedStreamedAmount = withdrawAmount;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier streamActive() {
        _;
    }

    /// @dev it should return zero.
    function test_GetStreamedAmount_CliffTimeGreaterThanCurrentTime() external streamActive {
        uint128 actualStreamedAmount = linear.getStreamedAmount(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier cliffTimeLessThanOrEqualToCurrentTime() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    function test_GetStreamedAmount() external streamActive cliffTimeLessThanOrEqualToCurrentTime {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint128 actualStreamedAmount = linear.getStreamedAmount(defaultStreamId);
        uint128 expectedStreamedAmount = 2_600e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
