// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { Lockup } from "@sablier/lockup/src/types/Lockup.sol";
import { LockupDynamic } from "@sablier/lockup/src/types/LockupDynamic.sol";

import { LockupBenchmark } from "./Benchmark.sol";

/// @notice Benchmarks for Lockup streams with an LD model.
/// @dev This contract creates a Markdown file with the gas usage of each function.
contract LockupDynamicBenchmark is LockupBenchmark {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint128[] internal _segmentCounts = [2, 10, 100];
    uint256[] internal _dynamicStreamIds = new uint256[](4);

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();
        IMM_RESULTS_FILE = "results/lockup/lockup-dynamic.md";
        vm.writeFile({
            path: IMM_RESULTS_FILE,
            data: string.concat(
                "With WETH as the streaming token.\n\n",
                "| Function | Segments | Configuration | Gas Usage |\n",
                "| :------- | :------- | :------------ | :-------- |\n"
            )
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     BENCHMARK
    //////////////////////////////////////////////////////////////////////////*/

    function test_LockupDynamicBenchmark() external {
        logBlue("\nStarting LockupDynamic benchmarks...");
        _setUpDynamicStreams({ segmentCount: 2 });

        /* ---------------------------------- BURN ---------------------------------- */

        logBlue("Benchmarking: burn...");
        uint256 gasUsed = instrument_Burn(_dynamicStreamIds[0]);
        _appendRow("burn", defaults.SEGMENT_COUNT(), "N/A", gasUsed);
        logGreen("Completed burn benchmark");

        /* --------------------------------- CANCEL --------------------------------- */

        logBlue("Benchmarking: cancel...");
        gasUsed = instrument_Cancel(_dynamicStreamIds[1]);
        _appendRow("cancel", defaults.SEGMENT_COUNT(), "N/A", gasUsed);
        logGreen("Completed cancel benchmark");

        /* -------------------------------- RENOUNCE -------------------------------- */

        logBlue("Benchmarking: renounce...");
        gasUsed = instrument_Renounce(_dynamicStreamIds[2]);
        _appendRow("renounce", defaults.SEGMENT_COUNT(), "N/A", gasUsed);
        logGreen("Completed renounce benchmark");

        /* ---------------------------- CREATE & WITHDRAW --------------------------- */

        logBlue("Benchmarking: create and withdraw with different segment counts...");
        string memory config;
        for (uint256 i; i < _segmentCounts.length; ++i) {
            logBlue(string.concat("Benchmarking with ", vm.toString(_segmentCounts[i]), " segments..."));

            // For the following two instrumentations, `_appendRow` is called within the functions.
            instrument_CreateWithDurationsLD(_segmentCounts[i]);
            instrument_CreateWithTimestampsLD(_segmentCounts[i]);

            _setUpDynamicStreams(_segmentCounts[i]);
            (gasUsed, config) = instrument_WithdrawOngoing(_dynamicStreamIds[0], users.recipient);
            _appendRow("withdraw", _segmentCounts[i], config, gasUsed);
            (gasUsed, config) = instrument_WithdrawCompleted(_dynamicStreamIds[1], users.recipient);
            _appendRow("withdraw", _segmentCounts[i], config, gasUsed);
            (gasUsed, config) = instrument_WithdrawOngoing(_dynamicStreamIds[2], users.alice);
            _appendRow("withdraw", _segmentCounts[i], config, gasUsed);
            (gasUsed, config) = instrument_WithdrawCompleted(_dynamicStreamIds[3], users.alice);
            _appendRow("withdraw", _segmentCounts[i], config, gasUsed);

            logGreen(string.concat("Completed benchmarks with ", vm.toString(_segmentCounts[i]), " segments"));
        }
        logGreen("Completed create and withdraw benchmarks");

        logBlue("\nCompleted all benchmarks");
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INSTRUMENTATION FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function instrument_CreateWithDurationsLD(uint128 segmentCount) internal {
        setMsgSender(users.sender);
        vm.warp({ newTimestamp: defaults.START_TIME() });

        (Lockup.CreateWithDurations memory params, LockupDynamic.SegmentWithDuration[] memory segments) =
            _paramsCreateWithDurationLD(segmentCount);
        uint256 beforeGas = gasleft();
        lockup.createWithDurationsLD(params, segments);
        uint256 gasUsed = beforeGas - gasleft();

        _appendRow("createWithDurationsLD", segmentCount, "N/A", gasUsed);
    }

    function instrument_CreateWithTimestampsLD(uint128 segmentCount) internal {
        setMsgSender(users.sender);

        (Lockup.CreateWithTimestamps memory params, LockupDynamic.Segment[] memory segments) =
            _paramsCreateWithTimestampsLD(segmentCount);

        uint256 beforeGas = gasleft();
        lockup.createWithTimestampsLD(params, segments);
        uint256 gasUsed = beforeGas - gasleft();

        _appendRow("createWithTimestampsLD", segmentCount, "N/A", gasUsed);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Append a row to the results file with the given function name, config, and gas used.
    function _appendRow(
        string memory functionName,
        uint256 segmentCount,
        string memory config,
        uint256 gasUsed
    )
        private
    {
        string memory row = string.concat(
            "| `", functionName, "` | ", vm.toString(segmentCount), " | ", config, " | ", vm.toString(gasUsed), " |"
        );
        vm.writeLine({ path: IMM_RESULTS_FILE, data: row });
    }

    function _paramsCreateWithDurationLD(uint128 segmentCount)
        private
        view
        returns (Lockup.CreateWithDurations memory params, LockupDynamic.SegmentWithDuration[] memory segments_)
    {
        segments_ = new LockupDynamic.SegmentWithDuration[](segmentCount);

        for (uint256 i = 0; i < segmentCount; ++i) {
            segments_[i] = (
                LockupDynamic.SegmentWithDuration({
                    amount: AMOUNT_PER_SEGMENT,
                    exponent: ud2x18(0.5e18),
                    duration: defaults.CLIFF_DURATION()
                })
            );
        }

        uint128 depositAmount = AMOUNT_PER_SEGMENT * segmentCount;

        params = defaults.createWithDurations();
        params.depositAmount = depositAmount;
        return (params, segments_);
    }

    function _paramsCreateWithTimestampsLD(uint128 segmentCount)
        private
        view
        returns (Lockup.CreateWithTimestamps memory params, LockupDynamic.Segment[] memory segments_)
    {
        segments_ = new LockupDynamic.Segment[](segmentCount);

        for (uint256 i = 0; i < segmentCount; ++i) {
            segments_[i] = (
                LockupDynamic.Segment({
                    amount: AMOUNT_PER_SEGMENT,
                    exponent: ud2x18(0.5e18),
                    timestamp: getBlockTimestamp() + uint40(defaults.CLIFF_DURATION() * (1 + i))
                })
            );
        }

        uint128 depositAmount = AMOUNT_PER_SEGMENT * segmentCount;

        params = defaults.createWithTimestamps();
        params.depositAmount = depositAmount;
        params.timestamps.start = getBlockTimestamp();
        params.timestamps.end = segments_[segmentCount - 1].timestamp;
        return (params, segments_);
    }

    function _setUpDynamicStreams(uint128 segmentCount) private {
        setMsgSender(users.sender);
        (Lockup.CreateWithDurations memory params, LockupDynamic.SegmentWithDuration[] memory segments) =
            _paramsCreateWithDurationLD(segmentCount);
        _dynamicStreamIds[0] = lockup.createWithDurationsLD(params, segments);
        _dynamicStreamIds[1] = lockup.createWithDurationsLD(params, segments);
        _dynamicStreamIds[2] = lockup.createWithDurationsLD(params, segments);
        _dynamicStreamIds[3] = lockup.createWithDurationsLD(params, segments);
    }
}
