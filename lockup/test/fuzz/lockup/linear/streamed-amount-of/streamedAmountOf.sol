// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Broker } from "src/types/Structs.sol";

import { Linear_Fuzz_Test } from "../Linear.t.sol";

contract StreamedAmountOf_Linear_Fuzz_Test is Linear_Fuzz_Test {
    uint256 internal defaultStreamId;

    modifier streamActive() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function testFuzz_StreamedAmountOf_CliffTimeGreaterThanCurrentTime(uint40 timeWarp) external streamActive {
        timeWarp = boundUint40(timeWarp, 0, DEFAULT_CLIFF_DURATION - 1);
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });
        uint128 actualStreamedAmount = linear.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier cliffTimeLessThanOrEqualToCurrentTime() {
        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank({ who: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        changePrank({ who: users.sender });
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
    function testFuzz_StreamedAmountOf(
        uint40 timeWarp,
        uint128 depositAmount
    ) external streamActive cliffTimeLessThanOrEqualToCurrentTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);
        vm.assume(depositAmount != 0);

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Mint enough assets to the sender.
        deal({ token: address(DEFAULT_ASSET), to: users.sender, give: depositAmount });

        // Create the stream.
        uint256 streamId = linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            depositAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            defaultParams.createWithRange.range,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Run the test.
        uint128 actualStreamedAmount = linear.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = calculateStreamedAmount(currentTime, depositAmount);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
