// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ud } from "@prb/math/src/UD60x18.sol";

import { Lockup, LockupLinear } from "../src/types/DataTypes.sol";

import { Benchmark_Test } from "./Benchmark.t.sol";

/// @notice Tests used to benchmark Lockup streams created using Linear model.
/// @dev This contract creates a Markdown file with the gas usage of each function.
contract Lockup_Linear_Gas_Test is Benchmark_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testGas_Implementations() external {
        // Set the file path.
        benchmarkResultsFile = string.concat(benchmarkResults, "SablierLockup_Linear.md");

        // Create the file if it doesn't exist, otherwise overwrite it.
        vm.writeFile({
            path: benchmarkResultsFile,
            data: string.concat(
                "# Benchmarks for the Lockup Linear model\n\n", "| Implementation | Gas Usage |\n", "| --- | --- |\n"
            )
        });

        vm.warp({ newTimestamp: defaults.END_TIME() });
        gasBurn();

        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        gasCancel();

        gasRenounce();

        gasCreateWithDurationsLL({ cliffDuration: 0 });
        gasCreateWithDurationsLL({ cliffDuration: defaults.CLIFF_DURATION() });

        gasCreateWithTimestampsLL({ cliffTime: 0 });
        gasCreateWithTimestampsLL({ cliffTime: defaults.CLIFF_TIME() });

        gasWithdraw_ByRecipient(streamIds[3], streamIds[4], "");
        gasWithdraw_ByAnyone(streamIds[5], streamIds[6], "");
    }

    /*//////////////////////////////////////////////////////////////////////////
                        GAS BENCHMARKS FOR CREATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function gasCreateWithDurationsLL(uint40 cliffDuration) internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time.
        resetPrank({ msgSender: users.sender });

        Lockup.CreateWithDurations memory params = defaults.createWithDurations();
        LockupLinear.Durations memory durations = defaults.durations();
        durations.cliff = cliffDuration;

        LockupLinear.UnlockAmounts memory unlockAmounts = defaults.unlockAmounts();
        if (cliffDuration == 0) unlockAmounts.cliff = 0;

        uint256 beforeGas = gasleft();
        lockup.createWithDurationsLL(params, unlockAmounts, durations);
        string memory gasUsed = vm.toString(beforeGas - gasleft());

        string memory cliffSetOrNot = cliffDuration == 0 ? " (cliff not set)" : " (cliff set)";

        contentToAppend =
            string.concat("| `createWithDurationsLL` (Broker fee set)", cliffSetOrNot, " | ", gasUsed, " |");

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Calculate gas usage without broker fee.
        params.broker.fee = ud(0);
        params.totalAmount = _calculateTotalAmount(defaults.DEPOSIT_AMOUNT(), ud(0));

        beforeGas = gasleft();
        lockup.createWithDurationsLL(params, unlockAmounts, durations);
        gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend =
            string.concat("| `createWithDurationsLL` (Broker fee not set)", cliffSetOrNot, " | ", gasUsed, " |");

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    function gasCreateWithTimestampsLL(uint40 cliffTime) internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time.
        resetPrank({ msgSender: users.sender });

        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestamps();
        LockupLinear.UnlockAmounts memory unlockAmounts = defaults.unlockAmounts();
        if (cliffTime == 0) unlockAmounts.cliff = 0;

        uint256 beforeGas = gasleft();
        lockup.createWithTimestampsLL(params, unlockAmounts, cliffTime);
        string memory gasUsed = vm.toString(beforeGas - gasleft());

        string memory cliffSetOrNot = cliffTime == 0 ? " (cliff not set)" : " (cliff set)";

        contentToAppend =
            string.concat("| `createWithTimestampsLL` (Broker fee set)", cliffSetOrNot, " | ", gasUsed, " |");

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Calculate gas usage without broker fee.
        params.broker.fee = ud(0);
        params.totalAmount = _calculateTotalAmount(defaults.DEPOSIT_AMOUNT(), ud(0));

        beforeGas = gasleft();
        lockup.createWithTimestampsLL(params, unlockAmounts, cliffTime);
        gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend =
            string.concat("| `createWithTimestampsLL` (Broker fee not set)", cliffSetOrNot, " | ", gasUsed, " |");

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }
}
