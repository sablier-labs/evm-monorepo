// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ZERO } from "@prb/math/UD60x18.sol";

import { Broker, LockupLinear } from "src/types/DataTypes.sol";

import { Linear_Fuzz_Test } from "../Linear.t.sol";

contract StreamedAmountOf_Linear_Fuzz_Test is Linear_Fuzz_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        Linear_Fuzz_Test.setUp();

        // Create the default stream.
        defaultStreamId = createDefaultStream();

        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        changePrank({ msgSender: users.sender });
    }

    modifier whenStreamActive() {
        _;
    }

    function testFuzz_StreamedAmountOf_CliffTimeInTheFuture(uint40 timeWarp) external whenStreamActive {
        timeWarp = boundUint40(timeWarp, 0, DEFAULT_CLIFF_DURATION - 1);
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });
        uint128 actualStreamedAmount = linear.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier whenCliffTimeInThePast() {
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Multiple deposit amounts
    function testFuzz_StreamedAmountOf_Calculation(
        uint40 timeWarp,
        uint128 depositAmount
    )
        external
        whenStreamActive
        whenCliffTimeInThePast
    {
        vm.assume(depositAmount != 0);
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Mint enough assets to the sender.
        deal({ token: address(DEFAULT_ASSET), to: users.sender, give: depositAmount });

        // Create the stream with the fuzzed deposit amount.
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.totalAmount = depositAmount;
        params.broker = Broker({ account: address(0), fee: ZERO });
        uint256 streamId = linear.createWithRange(params);

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualStreamedAmount = linear.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = calculateStreamedAmount(currentTime, depositAmount);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev The streamed amount must never go down over time.
    function testFuzz_StreamedAmountOf_Monotonicity(
        uint40 timeWarp0,
        uint40 timeWarp1,
        uint128 depositAmount
    )
        external
        whenStreamActive
        whenCliffTimeInThePast
    {
        vm.assume(depositAmount != 0);
        timeWarp0 = boundUint40(timeWarp0, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        timeWarp1 = boundUint40(timeWarp1, timeWarp0, DEFAULT_TOTAL_DURATION);

        // Mint enough assets to the sender.
        deal({ token: address(DEFAULT_ASSET), to: users.sender, give: depositAmount });

        // Create the stream with the fuzzed deposit amount.
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.totalAmount = depositAmount;
        uint256 streamId = linear.createWithRange(params);

        // Warp into the future for the first time.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp0 });

        // Calculate the streamed amount at this midpoint in time.
        uint128 streamedAmount0 = linear.streamedAmountOf(streamId);

        // Warp into the future for the second time.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp1 });

        // Assert that this streamed amount is greater than or equal to the previous streamed amount.
        uint128 streamedAmount1 = linear.streamedAmountOf(streamId);
        assertGte(streamedAmount1, streamedAmount0, "streamedAmount");
    }
}
