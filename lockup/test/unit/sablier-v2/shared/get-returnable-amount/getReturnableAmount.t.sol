// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract GetReturnableAmount_Test is SharedTest {
    uint256 internal defaultStreamId;

    /// @dev it should return zero.
    function test_GetReturnableAmount_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint256 actualReturnableAmount = sablierV2.getReturnableAmount(nullStreamId);
        uint256 expectedReturnableAmount = 0;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    modifier streamNonNull() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return the correct returnable amount.
    function testFuzz_GetReturnableAmount(uint256 timeWarp) external streamNonNull {
        timeWarp = bound(timeWarp, 0, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Get the streamedAmount amount.
        uint128 streamedAmount = sablierV2.getStreamedAmount(defaultStreamId);

        // Run the test.
        uint256 actualReturnableAmount = sablierV2.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = DEFAULT_NET_DEPOSIT_AMOUNT - streamedAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }
}
