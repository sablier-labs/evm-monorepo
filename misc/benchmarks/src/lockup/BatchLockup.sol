// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { BatchLockup } from "@sablier/lockup/src/types/BatchLockup.sol";
import { Lockup } from "@sablier/lockup/src/types/Lockup.sol";
import { LockupDynamic } from "@sablier/lockup/src/types/LockupDynamic.sol";
import { LockupTranched } from "@sablier/lockup/src/types/LockupTranched.sol";
import { BatchLockupBuilder } from "@sablier/lockup/tests/utils/Defaults.sol";

import { LockupBenchmark } from "./Benchmark.sol";

/// @notice Contract for benchmarking {SablierBatchLockup}.
/// @dev This contract creates a Markdown file with the gas usage of each function.
/// NOTE: this benchmark takes a long time to run.
contract BatchLockupBenchmark is LockupBenchmark {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint128 internal constant AMOUNT_PER_ITEM = 10e18;
    uint8[4] internal _batchSizes = [5, 10, 20, 50];
    uint8[4] internal _segmentCounts = [24, 24, 24, 12];

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();
        IMM_RESULTS_FILE = "results/lockup/batch-lockup.md";

        // Create the file if it doesn't exist, otherwise overwrite it.
        vm.writeFile({
            path: IMM_RESULTS_FILE,
            data: string.concat(
                "With WETH as the streaming token.\n\n",
                "| Lockup Model | Function | Batch Size | Segments/Tranches | Gas Usage |\n",
                "| :----------- | :------- | :--------- | :---------------- | :-------- |\n"
            )
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     BENCHMARK
    //////////////////////////////////////////////////////////////////////////*/

    function test_BatchLockupBenchmark() external {
        logBlue("\nStarting BatchLockup function benchmarks...");

        for (uint256 i = 0; i < _batchSizes.length; ++i) {
            logBlue(string.concat("Benchmarking batch size: ", vm.toString(_batchSizes[i])));

            // Benchmarks for LockupLinear.
            instrument_BatchCreateWithDurationsLL(_batchSizes[i]);
            instrument_BatchCreateWithTimestampsLL(_batchSizes[i]);

            // Benchmarks for LockupDynamic.
            instrument_BatchCreateWithDurationsLD({ batchSize: _batchSizes[i], segmentCount: _segmentCounts[i] });
            instrument_BatchCreateWithTimestampsLD({ batchSize: _batchSizes[i], segmentCount: _segmentCounts[i] });

            // Benchmarks for LockupTranched.
            instrument_BatchCreateWithDurationsLT({ batchSize: _batchSizes[i], trancheCount: _segmentCounts[i] });
            instrument_BatchCreateWithTimestampsLT({ batchSize: _batchSizes[i], trancheCount: _segmentCounts[i] });

            logGreen(string.concat("Completed batch size: ", vm.toString(_batchSizes[i])));
        }

        logBlue("\nCompleted all benchmarks");
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INSTRUMENTATION FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function instrument_BatchCreateWithDurationsLD(uint256 batchSize, uint256 segmentCount) internal {
        Lockup.CreateWithDurations memory createParams = defaults.createWithDurations();
        createParams.depositAmount = uint128(AMOUNT_PER_ITEM * segmentCount);
        LockupDynamic.SegmentWithDuration[] memory segments = _generateSegmentsWithDuration(segmentCount);
        BatchLockup.CreateWithDurationsLD[] memory batchParams =
            BatchLockupBuilder.fillBatch(createParams, segments, batchSize);

        uint256 initialGas = gasleft();
        batchLockup.createWithDurationsLD(lockup, weth, batchParams);
        uint256 gasUsed = initialGas - gasleft();

        _appendRow("createWithDurationsLD", "Dynamic", batchSize, vm.toString(segmentCount), gasUsed);
    }

    function instrument_BatchCreateWithTimestampsLD(uint256 batchSize, uint256 segmentCount) internal {
        Lockup.CreateWithTimestamps memory createParams = defaults.createWithTimestamps();
        LockupDynamic.Segment[] memory segments = _generateSegments(segmentCount);
        createParams.timestamps.start = getBlockTimestamp();
        createParams.timestamps.end = segments[segments.length - 1].timestamp;
        createParams.depositAmount = uint128(AMOUNT_PER_ITEM * segmentCount);
        BatchLockup.CreateWithTimestampsLD[] memory params =
            BatchLockupBuilder.fillBatch(createParams, segments, batchSize);

        uint256 initialGas = gasleft();
        batchLockup.createWithTimestampsLD(lockup, weth, params);
        uint256 gasUsed = initialGas - gasleft();

        _appendRow("createWithTimestampsLD", "Dynamic", batchSize, vm.toString(segmentCount), gasUsed);
    }

    function instrument_BatchCreateWithDurationsLL(uint256 batchSize) internal {
        BatchLockup.CreateWithDurationsLL[] memory batchParams = BatchLockupBuilder.fillBatch({
            params: defaults.createWithDurations(),
            unlockAmounts: defaults.unlockAmounts(),
            durations: defaults.durations(),
            batchSize: batchSize
        });

        uint256 initialGas = gasleft();
        batchLockup.createWithDurationsLL(lockup, weth, batchParams);
        uint256 gasUsed = initialGas - gasleft();

        _appendRow("createWithDurationsLL", "Linear", batchSize, "N/A", gasUsed);
    }

    function instrument_BatchCreateWithTimestampsLL(uint256 batchSize) internal {
        BatchLockup.CreateWithTimestampsLL[] memory batchParams = BatchLockupBuilder.fillBatch({
            params: defaults.createWithTimestamps(),
            unlockAmounts: defaults.unlockAmounts(),
            cliffTime: defaults.CLIFF_TIME(),
            batchSize: batchSize
        });

        uint256 initialGas = gasleft();
        batchLockup.createWithTimestampsLL(lockup, weth, batchParams);
        uint256 gasUsed = initialGas - gasleft();

        _appendRow("createWithTimestampsLL", "Linear", batchSize, "N/A", gasUsed);
    }

    function instrument_BatchCreateWithDurationsLT(uint256 batchSize, uint256 trancheCount) internal {
        Lockup.CreateWithDurations memory createParams = defaults.createWithDurations();
        LockupTranched.TrancheWithDuration[] memory tranches = _generateTranchesWithDuration(trancheCount);
        createParams.depositAmount = uint128(AMOUNT_PER_ITEM * trancheCount);
        BatchLockup.CreateWithDurationsLT[] memory batchParams =
            BatchLockupBuilder.fillBatch(createParams, tranches, batchSize);

        uint256 initialGas = gasleft();
        batchLockup.createWithDurationsLT(lockup, weth, batchParams);
        uint256 gasUsed = initialGas - gasleft();

        _appendRow("createWithDurationsLT", "Tranched", batchSize, vm.toString(trancheCount), gasUsed);
    }

    function instrument_BatchCreateWithTimestampsLT(uint256 batchSize, uint256 trancheCount) internal {
        Lockup.CreateWithTimestamps memory createParams = defaults.createWithTimestamps();
        LockupTranched.Tranche[] memory tranches = _generateTranches(trancheCount);
        createParams.timestamps.start = getBlockTimestamp();
        createParams.timestamps.end = tranches[tranches.length - 1].timestamp;
        createParams.depositAmount = uint128(AMOUNT_PER_ITEM * trancheCount);
        BatchLockup.CreateWithTimestampsLT[] memory batchParams =
            BatchLockupBuilder.fillBatch(createParams, tranches, batchSize);

        uint256 initialGas = gasleft();
        batchLockup.createWithTimestampsLT(lockup, weth, batchParams);
        uint256 gasUsed = initialGas - gasleft();

        _appendRow("createWithTimestampsLT", "Tranched", batchSize, vm.toString(trancheCount), gasUsed);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function _appendRow(
        string memory functionName,
        string memory lockupModel,
        uint256 batchSize,
        string memory segmentOrTrancheCount,
        uint256 gasUsed
    )
        private
    {
        string memory row = string.concat(
            " | ",
            lockupModel,
            "| `",
            functionName,
            "` | ",
            vm.toString(batchSize),
            " | ",
            segmentOrTrancheCount,
            " | ",
            vm.toString(gasUsed),
            " |"
        );
        vm.writeLine({ path: IMM_RESULTS_FILE, data: row });
    }

    function _generateSegments(uint256 segmentCount) private view returns (LockupDynamic.Segment[] memory) {
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](segmentCount);

        for (uint256 i = 0; i < segmentCount; ++i) {
            segments[i] = LockupDynamic.Segment({
                amount: AMOUNT_PER_ITEM,
                exponent: ud2x18(0.5e18),
                timestamp: getBlockTimestamp() + uint40(defaults.CLIFF_DURATION() * (1 + i))
            });
        }

        return segments;
    }

    function _generateSegmentsWithDuration(uint256 segmentCount)
        private
        view
        returns (LockupDynamic.SegmentWithDuration[] memory)
    {
        LockupDynamic.SegmentWithDuration[] memory segments = new LockupDynamic.SegmentWithDuration[](segmentCount);

        for (uint256 i; i < segmentCount; ++i) {
            segments[i] = LockupDynamic.SegmentWithDuration({
                amount: AMOUNT_PER_ITEM,
                exponent: ud2x18(0.5e18),
                duration: defaults.CLIFF_DURATION()
            });
        }

        return segments;
    }

    function _generateTranches(uint256 trancheCount) private view returns (LockupTranched.Tranche[] memory) {
        LockupTranched.Tranche[] memory tranches = new LockupTranched.Tranche[](trancheCount);

        for (uint256 i = 0; i < trancheCount; ++i) {
            tranches[i] = (
                LockupTranched.Tranche({
                    amount: AMOUNT_PER_ITEM,
                    timestamp: getBlockTimestamp() + uint40(defaults.CLIFF_DURATION() * (1 + i))
                })
            );
        }

        return tranches;
    }

    function _generateTranchesWithDuration(uint256 trancheCount)
        private
        view
        returns (LockupTranched.TrancheWithDuration[] memory)
    {
        LockupTranched.TrancheWithDuration[] memory tranches = new LockupTranched.TrancheWithDuration[](trancheCount);

        for (uint256 i; i < trancheCount; ++i) {
            tranches[i] =
                LockupTranched.TrancheWithDuration({ amount: AMOUNT_PER_ITEM, duration: defaults.CLIFF_DURATION() });
        }

        return tranches;
    }
}
