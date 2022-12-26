// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18, unwrap, wrap, ZERO } from "@prb/math/UD60x18.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract GetWithdrawableAmount__Test is LinearTest {
    uint256 internal defaultStreamId;

    /// @dev When the stream does not exist, it should return zero.
    function testGetWithdrawableAmount__StreamNonExistent() external {
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
    function testGetWithdrawableAmount__CliffTimeGreaterThanCurrentTime(uint40 timeWarp) external StreamExistent {
        timeWarp = boundUint40(timeWarp, 0, DEFAULT_CLIFF_DURATION - 1);
        vm.warp({ timestamp: defaultStream.startTime = timeWarp });
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
    function testGetWithdrawableAmount__CurrentTimeGreaterThanOrEqualToStopTime__NoWithdrawals(
        uint256 timeWarp
    ) external StreamExistent CliffTimeLessThanOrEqualToCurrentTime {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.stopTime + timeWarp });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = defaultStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount minus the withdrawn amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time > stop time
    /// - Current time = stop time
    /// - Withdraw amount equal to deposit amount and not
    function testGetWithdrawableAmount__CurrentTimeGreaterThanOrEqualToStopTime__WithWithdrawals(
        uint256 timeWarp,
        uint128 withdrawAmount
    ) external StreamExistent CliffTimeLessThanOrEqualToCurrentTime {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);
        withdrawAmount = boundUint128(withdrawAmount, 1, defaultStream.depositAmount);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.stopTime + timeWarp });

        // Withdraw the amount.
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = defaultStream.depositAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier CurrentTimeLessThanStopTime() {
        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank(users.owner);
        comptroller.setProtocolFee(defaultStream.token, ZERO);
        changePrank(users.sender);
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__NoWithdrawals(
        uint40 timeWarp,
        uint128 depositAmount
    ) external StreamExistent CliffTimeLessThanOrEqualToCurrentTime CurrentTimeLessThanStopTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        vm.assume(depositAmount != 0);

        // Mint tokens to the sender.
        deal({ token: defaultStream.token, to: defaultStream.sender, give: depositAmount });

        // Disable the operator fee so that it doesn't interfere with the calculations.
        UD60x18 operatorFee = ZERO;

        // Create the stream.
        uint256 streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            depositAmount,
            defaultArgs.createWithRange.operator,
            operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );

        // Warp into the future.
        uint40 currentTime = defaultStream.startTime + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmount(currentTime, depositAmount);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__WithWithdrawals(
        uint40 timeWarp,
        uint128 depositAmount,
        uint128 withdrawAmount
    ) external StreamExistent CliffTimeLessThanOrEqualToCurrentTime CurrentTimeLessThanStopTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        depositAmount = boundUint128(depositAmount, 10_000, UINT128_MAX);

        // Bound the withdraw amount.
        uint40 currentTime = defaultStream.startTime + timeWarp;
        uint128 initialWithdrawableAmount = calculateStreamedAmount(currentTime, depositAmount);
        withdrawAmount = boundUint128(withdrawAmount, 1, initialWithdrawableAmount);

        // Mint tokens to the sender.
        deal({ token: defaultStream.token, to: defaultStream.sender, give: depositAmount });

        // Disable the operator fee so that it doesn't interfere with the calculations.
        UD60x18 operatorFee = ZERO;

        // Create the stream with a custom gross deposit amount and operator fee.
        uint256 streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            depositAmount,
            defaultArgs.createWithRange.operator,
            operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
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
