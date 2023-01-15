// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Broker } from "src/types/Structs.sol";

import { Linear_Test } from "../Linear.t.sol";

contract GetStreamedAmount_Linear_Test is Linear_Test {
    uint256 internal defaultStreamId;

    /// @dev it should return zero.
    function test_GetStreamedAmount_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint128 actualStreamedAmount = linear.getStreamedAmount(nullStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount);
    }

    modifier streamNonNull() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function testFuzz_GetStreamedAmount_CliffTimeGreaterThanCurrentTime(uint40 timeWarp) external streamNonNull {
        timeWarp = boundUint40(timeWarp, 0, DEFAULT_CLIFF_DURATION - 1);
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });
        uint128 actualStreamedAmount = linear.getStreamedAmount(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount);
    }

    modifier cliffTimeLessThanOrEqualToCurrentTime() {
        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank(users.admin);
        comptroller.setProtocolFee(dai, ZERO);
        changePrank(users.sender);
        _;
    }

    /// @dev it should return the correct streamed amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time < stop time
    /// - Current time = stop time
    /// - Current time > stop time
    /// - Multiple values for the deposit amount
    function testFuzz_GetStreamedAmount(
        uint40 timeWarp,
        uint128 depositAmount
    ) external streamNonNull cliffTimeLessThanOrEqualToCurrentTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);
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
        uint128 actualStreamedAmount = linear.getStreamedAmount(streamId);
        uint128 expectedStreamedAmount = calculateStreamedAmount(currentTime, depositAmount);
        assertEq(actualStreamedAmount, expectedStreamedAmount);
    }
}
