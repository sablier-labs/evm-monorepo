// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { E, UD2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Broker, Segment } from "src/types/Structs.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract GetWithdrawableAmount_Pro_Unit_Test is Pro_Unit_Test {
    uint256 internal defaultStreamId;

    /// @dev it should return zero.
    function test_GetWithdrawableAmount_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(nullStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier streamNonNull() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function test_GetWithdrawableAmount_StartTimeGreaterThanCurrentTime() external streamNonNull {
        vm.warp({ timestamp: 0 });
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev it should return zero.
    function test_GetWithdrawableAmount_StartTimeEqualToCurrentTime() external streamNonNull {
        vm.warp({ timestamp: DEFAULT_START_TIME });
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier startTimeLessThanCurrentTime() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function test_GetWithdrawableAmount_WithoutWithdrawals() external streamNonNull startTimeLessThanCurrentTime {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION + 3_750 seconds });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        // The second term is 7,500*0.5^{0.5}
        uint128 expectedWithdrawableAmount = DEFAULT_SEGMENTS[0].amount + 5_303.30085889910643e18;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier withWithdrawals() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function test_GetWithdrawableAmount() external streamNonNull startTimeLessThanCurrentTime withWithdrawals {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION + 3_750 seconds });

        // Make the withdrawal.
        pro.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);

        // The second term is 7,500*0.5^{0.5}
        uint128 expectedWithdrawableAmount = DEFAULT_SEGMENTS[0].amount +
            5_303.30085889910643e18 -
            DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
