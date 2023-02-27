// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Broker, LockupLinear } from "src/types/DataTypes.sol";

import { Linear_Fuzz_Test } from "../Linear.t.sol";

contract WithdrawableAmountOf_Linear_Fuzz_Test is Linear_Fuzz_Test {
    uint256 internal defaultStreamId;
    modifier streamActive() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function testFuzz_WithdrawableAmountOf_CliffTimeGreaterThanCurrentTime(uint40 timeWarp) external streamActive {
        timeWarp = boundUint40(timeWarp, 0, DEFAULT_CLIFF_DURATION - 1);
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier cliffTimeLessThanOrEqualToCurrentTime() {
        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        changePrank({ msgSender: users.sender });
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time < end time
    /// - Current time = end time
    /// - Current time > end time
    /// - Multiple values for the deposit amount
    function testFuzz_WithdrawableAmountOf_NoWithdrawals(
        uint40 timeWarp,
        uint128 depositAmount
    ) external streamActive cliffTimeLessThanOrEqualToCurrentTime {
        vm.assume(depositAmount != 0);
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Mint enough ERC-20 assets to the sender.
        deal({ token: address(DEFAULT_ASSET), to: users.sender, give: depositAmount });

        // Create the stream. The broker fee is disabled so that it doesn't interfere with the calculations.
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.totalAmount = depositAmount;
        params.broker = Broker({ account: address(0), fee: ZERO });
        uint256 streamId = linear.createWithRange(params);

        // Run the test.
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmount(currentTime, depositAmount);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev it should return the correct withdrawable amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time < end time
    /// - Current time = end time
    /// - Current time > end time
    /// - Multiple values for the deposit amount
    /// - WithdrawFromLockupStream amount equal to deposit amount and not
    function testFuzz_WithdrawableAmountOf_WithWithdrawals(
        uint40 timeWarp,
        uint128 depositAmount,
        uint128 withdrawAmount
    ) external streamActive cliffTimeLessThanOrEqualToCurrentTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);
        depositAmount = boundUint128(depositAmount, 10_000, UINT128_MAX);

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Bound the withdraw amount.
        uint128 streamedAmount = calculateStreamedAmount(currentTime, depositAmount);
        withdrawAmount = boundUint128(withdrawAmount, 1, streamedAmount);

        // Mint enough ERC-20 assets to the sender.
        deal({ token: address(DEFAULT_ASSET), to: users.sender, give: depositAmount });

        // Create the stream. The broker fee is disabled so that it doesn't interfere with the calculations.
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.totalAmount = depositAmount;
        params.broker = Broker({ account: address(0), fee: ZERO });
        uint256 streamId = linear.createWithRange(params);

        // Make the withdrawal.
        linear.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount = streamedAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
