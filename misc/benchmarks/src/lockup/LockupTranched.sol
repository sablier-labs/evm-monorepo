// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Lockup } from "@sablier/lockup/src/types/Lockup.sol";
import { LockupTranched } from "@sablier/lockup/src/types/LockupTranched.sol";

import { LockupBenchmark } from "./Benchmark.sol";

/// @notice Benchmarks for Lockup streams with an LT model.
/// @dev This contract creates a Markdown file with the gas usage of each function.
contract LockupTranchedBenchmark is LockupBenchmark {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint128[] internal _trancheCounts = [2, 10, 100];
    uint256[] internal _tranchedStreamIds = new uint256[](4);

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();
        IMM_RESULTS_FILE = "results/lockup/lockup-tranched.md";
        vm.writeFile({
            path: IMM_RESULTS_FILE,
            data: string.concat(
                "With WETH as the streaming token.\n\n",
                "| Function | Tranches | Configuration | Gas Usage |\n",
                "| :------- | :------- | :------------ | :-------- |\n"
            )
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     BENCHMARK
    //////////////////////////////////////////////////////////////////////////*/

    function test_LockupTranchedBenchmark() external {
        logBlue("\nStarting LockupTranched benchmarks...");
        _setUpTranchedStreams({ trancheCount: 2 });

        /* ---------------------------------- BURN ---------------------------------- */

        logBlue("Benchmarking: burn...");
        uint256 gasUsed = instrument_Burn(_tranchedStreamIds[0]);
        _appendRow("burn", defaults.TRANCHE_COUNT(), "N/A", gasUsed);
        logGreen("Completed burn benchmark");

        /* --------------------------------- CANCEL --------------------------------- */

        logBlue("Benchmarking: cancel...");
        gasUsed = instrument_Cancel(_tranchedStreamIds[1]);
        _appendRow("cancel", defaults.TRANCHE_COUNT(), "N/A", gasUsed);
        logGreen("Completed cancel benchmark");

        /* -------------------------------- RENOUNCE -------------------------------- */

        logBlue("Benchmarking: renounce...");
        gasUsed = instrument_Renounce(_tranchedStreamIds[2]);
        _appendRow("renounce", defaults.TRANCHE_COUNT(), "N/A", gasUsed);
        logGreen("Completed renounce benchmark");

        /* ---------------------------- CREATE & WITHDRAW --------------------------- */

        logBlue("Benchmarking: create and withdraw with different segment counts...");
        string memory config;
        for (uint256 i; i < _trancheCounts.length; ++i) {
            logBlue(string.concat("Benchmarking with ", vm.toString(_trancheCounts[i]), " segments..."));

            // For the following two instrumentations, `_appendRow` is called within the functions.
            instrument_CreateWithDurationsLT(_trancheCounts[i]);
            instrument_CreateWithTimestampsLT(_trancheCounts[i]);

            _setUpTranchedStreams(_trancheCounts[i]);
            (gasUsed, config) = instrument_WithdrawOngoing(_tranchedStreamIds[0], users.recipient);
            _appendRow("withdraw", _trancheCounts[i], config, gasUsed);
            (gasUsed, config) = instrument_WithdrawCompleted(_tranchedStreamIds[1], users.recipient);
            _appendRow("withdraw", _trancheCounts[i], config, gasUsed);
            (gasUsed, config) = instrument_WithdrawOngoing(_tranchedStreamIds[2], users.alice);
            _appendRow("withdraw", _trancheCounts[i], config, gasUsed);
            (gasUsed, config) = instrument_WithdrawCompleted(_tranchedStreamIds[3], users.alice);
            _appendRow("withdraw", _trancheCounts[i], config, gasUsed);

            logGreen(string.concat("Completed benchmarks with ", vm.toString(_trancheCounts[i]), " segments"));
        }
        logGreen("Completed create and withdraw benchmarks");

        logBlue("\nCompleted all benchmarks");
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INSTRUMENTATION FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function instrument_CreateWithDurationsLT(uint128 trancheCount) internal {
        setMsgSender(users.sender);
        vm.warp({ newTimestamp: defaults.START_TIME() });

        (Lockup.CreateWithDurations memory params, LockupTranched.TrancheWithDuration[] memory tranches) =
            _paramsCreateWithDurationLT(trancheCount);

        uint256 beforeGas = gasleft();
        lockup.createWithDurationsLT(params, tranches);
        uint256 gasUsed = beforeGas - gasleft();

        _appendRow("createWithDurationsLT", trancheCount, "N/A", gasUsed);
    }

    function instrument_CreateWithTimestampsLT(uint128 trancheCount) internal {
        setMsgSender(users.sender);

        (Lockup.CreateWithTimestamps memory params, LockupTranched.Tranche[] memory tranches) =
            _paramsCreateWithTimestampsLT(trancheCount);
        uint256 beforeGas = gasleft();
        lockup.createWithTimestampsLT(params, tranches);
        uint256 gasUsed = beforeGas - gasleft();

        _appendRow("createWithTimestampsLT", trancheCount, "N/A", gasUsed);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Append a row to the results file with the given function name, config, and gas used.
    function _appendRow(
        string memory functionName,
        uint256 trancheCount,
        string memory config,
        uint256 gasUsed
    )
        private
    {
        string memory row = string.concat(
            "| `", functionName, "` | ", vm.toString(trancheCount), " | ", config, " | ", vm.toString(gasUsed), " |"
        );
        vm.writeLine({ path: IMM_RESULTS_FILE, data: row });
    }

    function _paramsCreateWithDurationLT(uint128 trancheCount)
        private
        view
        returns (Lockup.CreateWithDurations memory params, LockupTranched.TrancheWithDuration[] memory tranches_)
    {
        tranches_ = new LockupTranched.TrancheWithDuration[](trancheCount);

        // Populate tranches
        for (uint256 i = 0; i < trancheCount; ++i) {
            tranches_[i] = (
                LockupTranched.TrancheWithDuration({ amount: AMOUNT_PER_TRANCHE, duration: defaults.CLIFF_DURATION() })
            );
        }

        uint128 depositAmount = AMOUNT_PER_SEGMENT * trancheCount;

        params = defaults.createWithDurations();
        params.depositAmount = depositAmount;
        return (params, tranches_);
    }

    function _paramsCreateWithTimestampsLT(uint128 trancheCount)
        private
        view
        returns (Lockup.CreateWithTimestamps memory params, LockupTranched.Tranche[] memory tranches_)
    {
        tranches_ = new LockupTranched.Tranche[](trancheCount);

        for (uint256 i = 0; i < trancheCount; ++i) {
            tranches_[i] = (
                LockupTranched.Tranche({
                    amount: AMOUNT_PER_TRANCHE,
                    timestamp: getBlockTimestamp() + uint40(defaults.CLIFF_DURATION() * (1 + i))
                })
            );
        }

        uint128 depositAmount = AMOUNT_PER_SEGMENT * trancheCount;

        params = defaults.createWithTimestamps();
        params.timestamps.start = getBlockTimestamp();
        params.timestamps.end = tranches_[trancheCount - 1].timestamp;
        params.depositAmount = depositAmount;
        return (params, tranches_);
    }

    function _setUpTranchedStreams(uint128 trancheCount) private {
        setMsgSender(users.sender);
        (Lockup.CreateWithDurations memory params, LockupTranched.TrancheWithDuration[] memory tranches) =
            _paramsCreateWithDurationLT(trancheCount);
        _tranchedStreamIds[0] = lockup.createWithDurationsLT(params, tranches);
        _tranchedStreamIds[1] = lockup.createWithDurationsLT(params, tranches);
        _tranchedStreamIds[2] = lockup.createWithDurationsLT(params, tranches);
        _tranchedStreamIds[3] = lockup.createWithDurationsLT(params, tranches);
    }
}
