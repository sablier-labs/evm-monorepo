// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Linear_Unit_Test } from "../Linear.t.sol";

contract GetStreamedAmount_Linear_Unit_Test is Linear_Unit_Test {
    uint256 internal defaultStreamId;

    /// @dev it should return zero.
    function test_GetStreamedAmount_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint128 actualStreamedAmount = linear.getStreamedAmount(nullStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier streamNonNull() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function test_GetStreamedAmount_CliffTimeGreaterThanCurrentTime() external streamNonNull {
        uint128 actualStreamedAmount = linear.getStreamedAmount(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier cliffTimeLessThanOrEqualToCurrentTime() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    function test_GetStreamedAmount() external streamNonNull cliffTimeLessThanOrEqualToCurrentTime {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint128 actualStreamedAmount = linear.getStreamedAmount(defaultStreamId);
        uint128 expectedStreamedAmount = 2_600e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
