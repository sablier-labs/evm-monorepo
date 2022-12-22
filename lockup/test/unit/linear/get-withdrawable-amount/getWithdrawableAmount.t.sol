// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18, toUD60x18, unwrap, wrap, ZERO } from "@prb/math/UD60x18.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract GetWithdrawableAmount__Test is SablierV2LinearTest {
    uint256 internal defaultStreamId;

    /// @dev When the stream does not exist, it should return zero.
    function testGetWithdrawableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(nonStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier StreamExistent() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function testGetWithdrawableAmount__CliffTimeGreaterThanBlockTimestamp() external StreamExistent {
        vm.warp({ timestamp: defaultStream.cliffTime - 1 seconds });
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(defaultStreamId);
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
    /// - current time > stop time
    /// - current time = stop time
    function testGetWithdrawableAmount__CurrentTimeGreaterThanOrEqualToStopTime__NoWithdrawals(
        uint40 timeWarp
    ) external StreamExistent CliffTimeLessThanOrEqualToCurrentTime {
        timeWarp = boundUint40(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.stopTime + timeWarp });

        // Run the test.
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = defaultStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount minus the withdrawn amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - current time > stop time
    /// - current time = stop time
    function testGetWithdrawableAmount__CurrentTimeGreaterThanOrEqualToStopTime__WithWithdrawals(
        uint40 timeWarp,
        uint128 withdrawAmount
    ) external StreamExistent CliffTimeLessThanOrEqualToCurrentTime {
        timeWarp = boundUint40(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);
        withdrawAmount = boundUint128(withdrawAmount, 1, defaultStream.depositAmount);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.stopTime + timeWarp });

        // Withdraw the amount.
        sablierV2Linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = defaultStream.depositAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev Helper function that replicates the logic of the `getWithdrawableAmount` function.
    function calculateWithdrawableAmount(
        uint40 currentTime,
        uint128 depositAmount
    ) internal view returns (uint128 withdrawableAmount) {
        UD60x18 elapsedTime = toUD60x18(currentTime - defaultStream.startTime);
        UD60x18 totalTime = toUD60x18(defaultStream.stopTime - defaultStream.startTime);
        UD60x18 elapsedTimePercentage = elapsedTime.div(totalTime);
        UD60x18 streamedAmount = elapsedTimePercentage.mul(wrap(depositAmount));
        withdrawableAmount = uint128(unwrap(streamedAmount));
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__NoWithdrawals(
        uint40 timeWarp,
        uint128 depositAmount,
        uint8 tokenDecimals
    ) external StreamExistent CliffTimeLessThanOrEqualToCurrentTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        vm.assume(depositAmount != 0);

        // Create the token with the fuzzed token decimals and mint tokens to the sender.
        address token = deployAndDealToken({
            decimals: tokenDecimals,
            user: defaultStream.sender,
            give: depositAmount
        });

        // Approve the SablierV2Linear contract to transfer the tokens.
        IERC20(token).approve({ spender: address(sablierV2Linear), value: UINT256_MAX });

        // Create the stream.
        UD60x18 operatorFee = ZERO;
        uint256 streamId = sablierV2Linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            depositAmount,
            defaultArgs.createWithRange.operator,
            operatorFee,
            token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );

        // Warp into the future.
        uint40 currentTime = defaultStream.startTime + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateWithdrawableAmount(currentTime, depositAmount);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__WithWithdrawals(
        uint40 timeWarp,
        uint128 depositAmount,
        uint128 withdrawAmount,
        uint8 tokenDecimals
    ) external StreamExistent CliffTimeLessThanOrEqualToCurrentTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        depositAmount = boundUint128(depositAmount, 10_000, UINT128_MAX);

        // Bound the withdraw amount.
        uint40 currentTime = defaultStream.startTime + timeWarp;
        uint128 initialWithdrawableAmount = calculateWithdrawableAmount(currentTime, depositAmount);
        withdrawAmount = boundUint128(withdrawAmount, 1, initialWithdrawableAmount);

        // Create the token with the fuzzed token decimals and mint tokens to the sender.
        address token = deployAndDealToken({
            decimals: tokenDecimals,
            user: defaultStream.sender,
            give: depositAmount
        });

        // Approve the SablierV2Linear contract to transfer the tokens.
        IERC20(token).approve({ spender: address(sablierV2Linear), value: UINT256_MAX });

        // Create the stream.
        UD60x18 operatorFee = ZERO;
        uint256 streamId = sablierV2Linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            depositAmount,
            defaultArgs.createWithRange.operator,
            operatorFee,
            token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );

        // Warp into the future.
        vm.warp({ timestamp: currentTime });

        // Make the withdrawal.
        sablierV2Linear.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = initialWithdrawableAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}
