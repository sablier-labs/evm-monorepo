// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Broker } from "src/types/Structs.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract GetWithdrawableAmount_LinearTest is LinearTest {
    uint256 internal defaultStreamId;

    /// @dev When the stream does not exist, it should return zero.
    function test_GetWithdrawableAmount_StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(nonStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier StreamExistent() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function testFuzz_GetWithdrawableAmount_CliffTimeGreaterThanCurrentTime(uint40 timeWarp) external StreamExistent {
        timeWarp = boundUint40(timeWarp, 0, DEFAULT_CLIFF_DURATION - 1);
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier CliffTimeLessThanOrEqualToCurrentTime() {
        _;
    }

    /// @dev it should return the deposit amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time > stop time
    /// - Current time = stop time
    function testFuzz_GetWithdrawableAmount_CurrentTimeGreaterThanOrEqualToStopTime_NoWithdrawals(
        uint256 timeWarp
    ) external StreamExistent CliffTimeLessThanOrEqualToCurrentTime {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_STOP_TIME + timeWarp });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = DEFAULT_NET_DEPOSIT_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount minus the withdrawn amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time > stop time
    /// - Current time = stop time
    /// - Withdraw amount equal to deposit amount and not
    function testFuzz_GetWithdrawableAmount_CurrentTimeGreaterThanOrEqualToStopTime_WithWithdrawals(
        uint256 timeWarp,
        uint128 withdrawAmount
    ) external StreamExistent CliffTimeLessThanOrEqualToCurrentTime {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);
        withdrawAmount = boundUint128(withdrawAmount, 1, DEFAULT_NET_DEPOSIT_AMOUNT);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_STOP_TIME + timeWarp });

        // Withdraw the amount.
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = DEFAULT_NET_DEPOSIT_AMOUNT - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier CurrentTimeLessThanStopTime() {
        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank(users.admin);
        comptroller.setProtocolFee(dai, ZERO);
        changePrank(users.sender);
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testFuzz_GetWithdrawableAmount_NoWithdrawals(
        uint40 timeWarp,
        uint128 depositAmount
    ) external StreamExistent CliffTimeLessThanOrEqualToCurrentTime CurrentTimeLessThanStopTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        vm.assume(depositAmount != 0);

        // Mint enough tokens to the sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Create the stream. The broker fee is disabled so that it doesn't interfere with the calculations.
        uint256 streamId = linear.createWithRange(
            params.createWithRange.sender,
            params.createWithRange.recipient,
            depositAmount,
            params.createWithRange.token,
            params.createWithRange.cancelable,
            params.createWithRange.range,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmount(currentTime, depositAmount);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testFuzz_GetWithdrawableAmount_CurrentTimeLessThanStopTime_WithWithdrawals(
        uint40 timeWarp,
        uint128 depositAmount,
        uint128 withdrawAmount
    ) external StreamExistent CliffTimeLessThanOrEqualToCurrentTime CurrentTimeLessThanStopTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        depositAmount = boundUint128(depositAmount, 10_000, UINT128_MAX);

        // Bound the withdraw amount.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        uint128 initialWithdrawableAmount = calculateStreamedAmount(currentTime, depositAmount);
        withdrawAmount = boundUint128(withdrawAmount, 1, initialWithdrawableAmount);

        // Mint enough tokens to the sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Create the stream with a custom gross deposit amount. The broker fee is disabled so that it doesn't interfere
        // with the calculations.
        uint256 streamId = linear.createWithRange(
            params.createWithRange.sender,
            params.createWithRange.recipient,
            depositAmount,
            params.createWithRange.token,
            params.createWithRange.cancelable,
            params.createWithRange.range,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Warp into the future.
        vm.warp({ timestamp: currentTime });

        // Make the withdrawal.
        linear.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = initialWithdrawableAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}
