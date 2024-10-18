// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ud21x18 } from "@prb/math/src/UD21x18.sol";

import { Integration_Test } from "./../tests/integration/Integration.t.sol";

/// @notice A contract to benchmark Flow functions.
/// @dev This contract creates a Markdown file with the gas usage of each function.
contract Flow_Gas_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The path to the file where the benchmark results are stored.
    string internal benchmarkResultsFile = "benchmark/results/SablierFlow.md";

    uint256 internal streamId;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        Integration_Test.setUp();

        // Setup a few streams with usdc.
        for (uint8 count; count < 100; ++count) {
            depositDefaultAmount({ streamId: createDefaultStream() });
        }

        // Set the streamId to 50 for the test function.
        streamId = 50;

        // Create the file if it doesn't exist, otherwise overwrite it.
        vm.writeFile({
            path: benchmarkResultsFile,
            data: string.concat("# Benchmarks using 6-decimal token \n\n", "| Function | Gas Usage |\n", "| --- | --- |\n")
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testGas_Implementations() external {
        // {flow.adjustRatePerSecond}
        computeGas(
            "adjustRatePerSecond",
            abi.encodeCall(flow.adjustRatePerSecond, (streamId, ud21x18(RATE_PER_SECOND_U128 + 1)))
        );

        // {flow.create}
        computeGas(
            "create", abi.encodeCall(flow.create, (users.sender, users.recipient, RATE_PER_SECOND, usdc, TRANSFERABLE))
        );

        // {flow.deposit}
        computeGas(
            "deposit", abi.encodeCall(flow.deposit, (streamId, DEPOSIT_AMOUNT_6D, users.sender, users.recipient))
        );

        // {flow.depositViaBroker}
        computeGas(
            "depositViaBroker",
            abi.encodeCall(
                flow.depositViaBroker,
                (streamId, TOTAL_AMOUNT_WITH_BROKER_FEE_6D, users.sender, users.recipient, defaultBroker)
            )
        );

        // {flow.pause}
        computeGas("pause", abi.encodeCall(flow.pause, (streamId)));

        // {flow.refund}
        computeGas("refund", abi.encodeCall(flow.refund, (streamId, REFUND_AMOUNT_6D)));

        // {flow.restart}
        computeGas("restart", abi.encodeCall(flow.restart, (streamId, RATE_PER_SECOND)));

        // {flow.void} (on a solvent stream)
        computeGas("void (solvent stream)", abi.encodeCall(flow.void, (streamId)));

        // Warp time to accrue uncovered debt for the next call on an incremented stream ID..
        vm.warp(flow.depletionTimeOf(++streamId) + 2 days);

        // {flow.void} (on an insolvent stream)
        computeGas("void (insolvent stream)", abi.encodeCall(flow.void, (streamId)));

        // {flow.withdraw} (on an insolvent stream) on an incremented stream ID.
        computeGas(
            "withdraw (insolvent stream)",
            abi.encodeCall(flow.withdraw, (++streamId, users.recipient, WITHDRAW_AMOUNT_6D))
        );

        // Deposit amount on an incremented stream ID to make stream solvent.
        deposit(++streamId, uint128(flow.uncoveredDebtOf(streamId)) + DEPOSIT_AMOUNT_6D);

        // {flow.withdraw} (on a solvent stream).
        computeGas(
            "withdraw (solvent stream)", abi.encodeCall(flow.withdraw, (streamId, users.recipient, WITHDRAW_AMOUNT_6D))
        );

        // {flow.withdrawMax} on an incremented stream ID.
        computeGas("withdrawMax", abi.encodeCall(flow.withdrawMax, (++streamId, users.recipient)));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Compute gas usage of a given function using low-level call.
    function computeGas(string memory name, bytes memory payload) internal {
        // Simulate the passage of time.
        vm.warp(getBlockTimestamp() + 2 days);

        uint256 initialGas = gasleft();
        (bool status,) = address(flow).call(payload);
        string memory gasUsed = vm.toString(initialGas - gasleft());

        // Ensure the function call was successful.
        require(status, "Benchmark: call failed");

        // Append the gas usage to the benchmark results file.
        string memory contentToAppend = string.concat("| `", name, "` | ", gasUsed, " |");
        vm.writeLine({ path: benchmarkResultsFile, data: contentToAppend });
    }
}
