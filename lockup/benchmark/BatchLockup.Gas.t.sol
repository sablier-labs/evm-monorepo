// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { LockupDynamic, LockupLinear, LockupTranched } from "../src/core/types/DataTypes.sol";
import { BatchLockup } from "../src/periphery/types/DataTypes.sol";
import { BatchLockupBuilder } from "../test/utils/BatchLockupBuilder.sol";

import { Benchmark_Test } from "./Benchmark.t.sol";

/// @notice Tests used to benchmark {BatchLockup}.
/// @dev This contract creates a Markdown file with the gas usage of each function.
contract BatchLockup_Gas_Test is Benchmark_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint128 internal constant AMOUNT_PER_ITEM = 10e18;
    uint8[5] internal batches = [5, 10, 20, 30, 50];
    uint8[5] internal counts = [24, 24, 24, 24, 12];

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testGas_Implementations() external {
        // Set the file path.
        benchmarkResultsFile = string.concat(benchmarkResults, "SablierBatchLockup.md");

        // Create the file if it doesn't exist, otherwise overwrite it.
        vm.writeFile({
            path: benchmarkResultsFile,
            data: string.concat(
                "# Benchmarks for BatchLockup\n\n",
                "| Function | Lockup Type | Segments/Tranches | Batch Size | Gas Usage |\n",
                "| --- | --- | --- | --- | --- |\n"
            )
        });

        for (uint256 i; i < batches.length; ++i) {
            // Benchmark the batch create functions for Lockup Linear.
            gasCreateWithDurationsLL(batches[i]);
            gasCreateWithTimestampsLL(batches[i]);

            // Benchmark the batch create functions for Lockup Dynamic.
            gasCreateWithDurationsLD({ batchSize: batches[i], segmentsCount: counts[i] });
            gasCreateWithTimestampsLD({ batchSize: batches[i], segmentsCount: counts[i] });

            // Benchmark the batch create functions for Lockup Tranched.
            gasCreateWithDurationsLT({ batchSize: batches[i], tranchesCount: counts[i] });
            gasCreateWithTimestampsLT({ batchSize: batches[i], tranchesCount: counts[i] });
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                        GAS BENCHMARKS FOR BATCH FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function gasCreateWithDurationsLD(uint256 batchSize, uint256 segmentsCount) internal {
        LockupDynamic.CreateWithDurations memory createParams = defaults.createWithDurationsBrokerNullLD();
        createParams.totalAmount = uint128(AMOUNT_PER_ITEM * segmentsCount);
        createParams.segments = _generateSegmentsWithDuration(segmentsCount);
        BatchLockup.CreateWithDurationsLD[] memory params = BatchLockupBuilder.fillBatch(createParams, batchSize);

        uint256 initialGas = gasleft();
        batchLockup.createWithDurationsLD(lockupDynamic, dai, params);
        string memory gasUsed = vm.toString(initialGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithDurationsLD` | Lockup Dynamic |",
            vm.toString(segmentsCount),
            " |",
            vm.toString(batchSize),
            " | ",
            gasUsed,
            " |"
        );

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    function gasCreateWithTimestampsLD(uint256 batchSize, uint256 segmentsCount) internal {
        LockupDynamic.CreateWithTimestamps memory createParams = defaults.createWithTimestampsBrokerNullLD();
        createParams.startTime = getBlockTimestamp();
        createParams.totalAmount = uint128(AMOUNT_PER_ITEM * segmentsCount);
        createParams.segments = _generateSegments(segmentsCount);
        BatchLockup.CreateWithTimestampsLD[] memory params = BatchLockupBuilder.fillBatch(createParams, batchSize);

        uint256 initialGas = gasleft();
        batchLockup.createWithTimestampsLD(lockupDynamic, dai, params);
        string memory gasUsed = vm.toString(initialGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithTimestampsLD` | Lockup Dynamic |",
            vm.toString(segmentsCount),
            " |",
            vm.toString(batchSize),
            " | ",
            gasUsed,
            " |"
        );

        // Append the data to the file
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    function gasCreateWithDurationsLL(uint256 batchSize) internal {
        BatchLockup.CreateWithDurationsLL[] memory params =
            BatchLockupBuilder.fillBatch({ params: defaults.createWithDurationsBrokerNullLL(), batchSize: batchSize });

        uint256 initialGas = gasleft();
        batchLockup.createWithDurationsLL(lockupLinear, dai, params);
        string memory gasUsed = vm.toString(initialGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithDurationsLL` | Lockup Linear | N/A |", vm.toString(batchSize), " | ", gasUsed, " |"
        );

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    function gasCreateWithTimestampsLL(uint256 batchSize) internal {
        BatchLockup.CreateWithTimestampsLL[] memory params =
            BatchLockupBuilder.fillBatch({ params: defaults.createWithTimestampsBrokerNullLL(), batchSize: batchSize });

        uint256 initialGas = gasleft();
        batchLockup.createWithTimestampsLL(lockupLinear, dai, params);
        string memory gasUsed = vm.toString(initialGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithTimestampsLL` | Lockup Linear | N/A |", vm.toString(batchSize), " | ", gasUsed, " |"
        );

        // Append the data to the file
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    function gasCreateWithDurationsLT(uint256 batchSize, uint256 tranchesCount) internal {
        LockupTranched.CreateWithDurations memory createParams = defaults.createWithDurationsBrokerNullLT();
        createParams.totalAmount = uint128(AMOUNT_PER_ITEM * tranchesCount);
        createParams.tranches = _generateTranchesWithDuration(tranchesCount);
        BatchLockup.CreateWithDurationsLT[] memory params = BatchLockupBuilder.fillBatch(createParams, batchSize);

        uint256 initialGas = gasleft();
        batchLockup.createWithDurationsLT(lockupTranched, dai, params);
        string memory gasUsed = vm.toString(initialGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithDurationsLT` | Lockup Tranched |",
            vm.toString(tranchesCount),
            " |",
            vm.toString(batchSize),
            " | ",
            gasUsed,
            " |"
        );

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    function gasCreateWithTimestampsLT(uint256 batchSize, uint256 tranchesCount) internal {
        LockupTranched.CreateWithTimestamps memory createParams = defaults.createWithTimestampsBrokerNullLT();
        createParams.startTime = getBlockTimestamp();
        createParams.totalAmount = uint128(AMOUNT_PER_ITEM * tranchesCount);
        createParams.tranches = _generateTranches(tranchesCount);
        BatchLockup.CreateWithTimestampsLT[] memory params = BatchLockupBuilder.fillBatch(createParams, batchSize);

        uint256 initialGas = gasleft();
        batchLockup.createWithTimestampsLT(lockupTranched, dai, params);
        string memory gasUsed = vm.toString(initialGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithTimestampsLT` | Lockup Tranched |",
            vm.toString(tranchesCount),
            " |",
            vm.toString(batchSize),
            " | ",
            gasUsed,
            " |"
        );

        // Append the data to the file
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function _generateSegments(uint256 segmentsCount) private view returns (LockupDynamic.Segment[] memory) {
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](segmentsCount);

        // Populate segments.
        for (uint256 i = 0; i < segmentsCount; ++i) {
            segments[i] = LockupDynamic.Segment({
                amount: AMOUNT_PER_ITEM,
                exponent: ud2x18(0.5e18),
                timestamp: getBlockTimestamp() + uint40(defaults.CLIFF_DURATION() * (1 + i))
            });
        }

        return segments;
    }

    function _generateSegmentsWithDuration(uint256 segmentsCount)
        private
        view
        returns (LockupDynamic.SegmentWithDuration[] memory)
    {
        LockupDynamic.SegmentWithDuration[] memory segments = new LockupDynamic.SegmentWithDuration[](segmentsCount);

        // Populate segments.
        for (uint256 i; i < segmentsCount; ++i) {
            segments[i] = LockupDynamic.SegmentWithDuration({
                amount: AMOUNT_PER_ITEM,
                exponent: ud2x18(0.5e18),
                duration: defaults.CLIFF_DURATION()
            });
        }

        return segments;
    }

    function _generateTranches(uint256 tranchesCount) private view returns (LockupTranched.Tranche[] memory) {
        LockupTranched.Tranche[] memory tranches = new LockupTranched.Tranche[](tranchesCount);

        // Populate tranches.
        for (uint256 i = 0; i < tranchesCount; ++i) {
            tranches[i] = (
                LockupTranched.Tranche({
                    amount: AMOUNT_PER_ITEM,
                    timestamp: getBlockTimestamp() + uint40(defaults.CLIFF_DURATION() * (1 + i))
                })
            );
        }

        return tranches;
    }

    function _generateTranchesWithDuration(uint256 tranchesCount)
        private
        view
        returns (LockupTranched.TrancheWithDuration[] memory)
    {
        LockupTranched.TrancheWithDuration[] memory tranches = new LockupTranched.TrancheWithDuration[](tranchesCount);

        // Populate tranches.
        for (uint256 i; i < tranchesCount; ++i) {
            tranches[i] =
                LockupTranched.TrancheWithDuration({ amount: AMOUNT_PER_ITEM, duration: defaults.CLIFF_DURATION() });
        }

        return tranches;
    }
}
