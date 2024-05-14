// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ud } from "@prb/math/src/UD60x18.sol";

import { LockupLinear } from "../src/types/DataTypes.sol";

import { Benchmark_Test } from "./Benchmark.t.sol";

/// @notice Tests used to benchmark LockupLinear.
/// @dev This contract creates a Markdown file with the gas usage of each function.
contract LockupLinear_Gas_Test is Benchmark_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();

        lockup = lockupLinear;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testGas_Implementations() external {
        // Set the file path.
        benchmarkResultsFile = string.concat(benchmarkResults, "SablierV2LockupLinear.md");

        // Create the file if it doesn't exist, otherwise overwrite it.
        vm.writeFile({
            path: benchmarkResultsFile,
            data: string.concat("# Benchmarks for LockupLinear\n\n", "| Implementation | Gas Usage |\n", "| --- | --- |\n")
        });

        vm.warp({ newTimestamp: defaults.END_TIME() });
        gasBurn();

        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        gasCancel();

        gasRenounce();

        gasCreateWithDurations({ cliffDuration: 0 });
        gasCreateWithDurations({ cliffDuration: defaults.CLIFF_DURATION() });

        gasCreateWithTimestamps({ cliffTime: 0 });
        gasCreateWithTimestamps({ cliffTime: defaults.CLIFF_TIME() });

        gasWithdraw_ByRecipient(streamIds[3], streamIds[4], "");
        gasWithdraw_ByAnyone(streamIds[5], streamIds[6], "");
    }

    /*//////////////////////////////////////////////////////////////////////////
                        GAS BENCHMARKS FOR CREATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function gasCreateWithDurations(uint40 cliffDuration) internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time.
        resetPrank({ msgSender: users.sender });

        LockupLinear.CreateWithDurations memory params = defaults.createWithDurationsLL();
        params.durations.cliff = cliffDuration;

        uint256 beforeGas = gasleft();
        lockupLinear.createWithDurations(params);
        string memory gasUsed = vm.toString(beforeGas - gasleft());

        string memory cliffSetOrNot = cliffDuration == 0 ? " (cliff not set)" : " (cliff set)";

        contentToAppend = string.concat("| `createWithDurations` (Broker fee set)", cliffSetOrNot, " | ", gasUsed, " |");

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Calculate gas usage without broker fee.
        params.broker.fee = ud(0);
        params.totalAmount = _calculateTotalAmount(defaults.DEPOSIT_AMOUNT(), ud(0));

        beforeGas = gasleft();
        lockupLinear.createWithDurations(params);
        gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend =
            string.concat("| `createWithDurations` (Broker fee not set)", cliffSetOrNot, " | ", gasUsed, " |");

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    function gasCreateWithTimestamps(uint40 cliffTime) internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time.
        resetPrank({ msgSender: users.sender });

        LockupLinear.CreateWithTimestamps memory params = defaults.createWithTimestampsLL();
        params.timestamps.cliff = cliffTime;

        uint256 beforeGas = gasleft();
        lockupLinear.createWithTimestamps(params);
        string memory gasUsed = vm.toString(beforeGas - gasleft());

        string memory cliffSetOrNot = cliffTime == 0 ? " (cliff not set)" : " (cliff set)";

        contentToAppend =
            string.concat("| `createWithTimestamps` (Broker fee set)", cliffSetOrNot, " | ", gasUsed, " |");

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Calculate gas usage without broker fee.
        params.broker.fee = ud(0);
        params.totalAmount = _calculateTotalAmount(defaults.DEPOSIT_AMOUNT(), ud(0));

        beforeGas = gasleft();
        lockupLinear.createWithTimestamps(params);
        gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend =
            string.concat("| `createWithTimestamps` (Broker fee not set)", cliffSetOrNot, " | ", gasUsed, " |");

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }
}
