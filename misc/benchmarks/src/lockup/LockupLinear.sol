// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Lockup } from "@sablier/lockup/src/types/Lockup.sol";
import { LockupLinear } from "@sablier/lockup/src/types/LockupLinear.sol";

import { LockupBenchmark } from "./Benchmark.sol";

/// @notice Benchmarks for Lockup streams with an LL model.
/// @dev This contract creates a Markdown file with the gas usage of each function.
contract LockupLinearBenchmark is LockupBenchmark {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256[] internal _linearStreamIds = new uint256[](4);

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();
        IMM_RESULTS_FILE = "results/lockup/lockup-linear.md";
        vm.writeFile({
            path: IMM_RESULTS_FILE,
            data: string.concat(
                "With WETH as the streaming token.\n\n",
                "| Function | Configuration | Gas Usage |\n",
                "| :------- | :------------ | :-------- |\n"
            )
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     BENCHMARK
    //////////////////////////////////////////////////////////////////////////*/

    function test_LockupLinearBenchmark() external {
        logBlue("\nStarting LockupLinear benchmarks...");
        _setUpLinearStreams();

        /* ---------------------------------- BURN ---------------------------------- */
        logBlue("Benchmarking: burn...");
        uint256 gasUsed = instrument_Burn(_linearStreamIds[0]);
        _appendRow("burn", "N/A", gasUsed);
        logGreen("Completed burn benchmark");

        /* --------------------------------- CANCEL --------------------------------- */

        logBlue("Benchmarking: cancel...");
        gasUsed = instrument_Cancel(_linearStreamIds[1]);
        _appendRow("cancel", "N/A", gasUsed);
        logGreen("Completed cancel benchmark");

        /* -------------------------------- RENOUNCE -------------------------------- */

        logBlue("Benchmarking: renounce...");
        gasUsed = instrument_Renounce(_linearStreamIds[2]);
        _appendRow("renounce", "N/A", gasUsed);
        logGreen("Completed renounce benchmark");

        /* --------------------------------- CREATE --------------------------------- */

        logBlue("Benchmarking: create with different cliffs...");

        // For the following two instrumentations, `_appendRow` is called within the functions.
        instrument_CreateWithDurationsLL({ cliffDuration: 0 });
        instrument_CreateWithDurationsLL({ cliffDuration: defaults.CLIFF_DURATION() });
        instrument_CreateWithTimestampsLL({ cliffTime: 0 });
        instrument_CreateWithTimestampsLL({ cliffTime: defaults.CLIFF_TIME() });
        logGreen("Completed create benchmarks");

        /* -------------------------------- WITHDRAW -------------------------------- */

        logBlue("Benchmarking: withdraw...");
        string memory config;
        _setUpLinearStreams();
        (gasUsed, config) = instrument_WithdrawOngoing(_linearStreamIds[0], users.recipient);
        _appendRow("withdraw", config, gasUsed);
        (gasUsed, config) = instrument_WithdrawCompleted(_linearStreamIds[1], users.recipient);
        _appendRow("withdraw", config, gasUsed);
        (gasUsed, config) = instrument_WithdrawOngoing(_linearStreamIds[2], users.alice);
        _appendRow("withdraw", config, gasUsed);
        (gasUsed, config) = instrument_WithdrawCompleted(_linearStreamIds[3], users.alice);
        _appendRow("withdraw", config, gasUsed);

        logGreen("Completed withdraw benchmarks");

        logBlue("\nCompleted all benchmarks");
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INSTRUMENTATION FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function instrument_CreateWithDurationsLL(uint40 cliffDuration) internal {
        setMsgSender(users.sender);
        vm.warp({ newTimestamp: defaults.START_TIME() });

        Lockup.CreateWithDurations memory params = defaults.createWithDurations();
        LockupLinear.Durations memory durations = defaults.durations();
        durations.cliff = cliffDuration;

        LockupLinear.UnlockAmounts memory unlockAmounts = defaults.unlockAmounts();
        if (cliffDuration == 0) unlockAmounts.cliff = 0;

        uint256 beforeGas = gasleft();
        lockup.createWithDurationsLL(params, unlockAmounts, durations);
        uint256 gasUsed = beforeGas - gasleft();

        string memory cliffConfig = cliffDuration == 0 ? "no cliff" : " with cliff";
        _appendRow("createWithDurationsLL", cliffConfig, gasUsed);
    }

    function instrument_CreateWithTimestampsLL(uint40 cliffTime) internal {
        setMsgSender(users.sender);

        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestamps();

        LockupLinear.UnlockAmounts memory unlockAmounts = defaults.unlockAmounts();
        if (cliffTime == 0) unlockAmounts.cliff = 0;

        uint256 beforeGas = gasleft();
        lockup.createWithTimestampsLL(params, unlockAmounts, cliffTime);
        uint256 gasUsed = beforeGas - gasleft();

        string memory cliffConfig = cliffTime == 0 ? "no cliff" : " with cliff";
        _appendRow("createWithTimestampsLL", cliffConfig, gasUsed);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Append a row to the results file with the given function name, configuration, and gas used.
    function _appendRow(string memory functionName, string memory configuration, uint256 gasUsed) private {
        string memory row = string.concat("| `", functionName, "` | ", configuration, " | ", vm.toString(gasUsed), " |");
        vm.writeLine({ path: IMM_RESULTS_FILE, data: row });
    }

    function _setUpLinearStreams() private {
        setMsgSender(users.sender);

        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestamps();

        _linearStreamIds[0] = lockup.createWithTimestampsLL({
            params: params,
            unlockAmounts: defaults.unlockAmounts(),
            cliffTime: defaults.CLIFF_TIME()
        });
        _linearStreamIds[1] = lockup.createWithTimestampsLL({
            params: params,
            unlockAmounts: defaults.unlockAmounts(),
            cliffTime: defaults.CLIFF_TIME()
        });

        _linearStreamIds[2] = lockup.createWithTimestampsLL({
            params: params,
            unlockAmounts: defaults.unlockAmounts(),
            cliffTime: defaults.CLIFF_TIME()
        });
        _linearStreamIds[3] = lockup.createWithTimestampsLL({
            params: params,
            unlockAmounts: defaults.unlockAmounts(),
            cliffTime: defaults.CLIFF_TIME()
        });
    }
}
